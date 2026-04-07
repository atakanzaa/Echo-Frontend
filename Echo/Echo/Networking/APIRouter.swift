import Foundation

enum APIRouter {
    // Auth
    case register(RegisterBody)
    case login(LoginBody)
    case refreshToken(RefreshBody)
    case logout(LogoutBody)
    case me

    // Users
    case userStats
    case updateProfile(UpdateProfileBody)

    // Journal
    case uploadJournalEntry(audioData: Data, filename: String, recordedAt: String, durationSeconds: Int)
    case getJournalEntry(id: String)
    case getJournalEntryStatus(id: String)
    case getJournalEntriesByDate(date: String)
    case getRecentJournalEntries(limit: Int)

    // Summary
    case getSummary(period: Int, endDate: String?)

    // Calendar
    case getCalendarMonth(year: Int, month: Int)

    // AI Insights
    case getAIInsights(period: Int)

    // Community
    case getCommunityFeed(tab: CommunityTab, page: Int, size: Int)
    case getCommunityPost(id: String)
    case createCommunityPost(CreatePostBody)
    case createCommunityPostWithImage(imageData: Data, filename: String, content: String?, emoji: String?, isAnonymous: Bool)
    case deleteCommunityPost(id: String)
    case likeCommunityPost(id: String)
    case unlikeCommunityPost(id: String)
    case getPostComments(postId: String, page: Int, size: Int)
    case createComment(postId: String, body: CreateCommentBody)
    case deleteComment(postId: String, commentId: String)
    case followUser(userId: String)
    case unfollowUser(userId: String)
    case likeComment(commentId: String)
    case unlikeComment(commentId: String)

    // Achievements
    case getAchievements

    // Time Capsule
    case getCapsules
    case createCapsule(audioData: Data?, filename: String?, body: CreateCapsuleBody)
    case getCapsule(id: String)
    case deleteCapsule(id: String)

    // Coach
    case getCoachSessions(page: Int, size: Int)
    case endCoachSession(sessionId: String)
    case createCoachSession
    case createCoachSessionWithJournal(journalEntryId: String)
    case getCoachMessages(sessionId: String)
    case sendCoachMessage(sessionId: String, body: SendCoachMessageBody)
    case deleteCoachSession(id: String)

    // Goals
    case getActiveGoals
    case getAllGoals
    case completeGoal(id: String)
    case dismissGoal(id: String)

    // Admin
    case getAIConfig
    case updateAIConfig(AIConfigBody)

    // Health
    case health
}

// MARK: — URLRequest Builder

extension APIRouter {
    func asURLRequest() throws -> URLRequest {
        let (path, method, body, isMultipart) = components()

        guard let url = URL(string: AppConstants.API.baseURL + path) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeoutInterval

        if let body = body, !isMultipart {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        return request
    }

    private var timeoutInterval: TimeInterval {
        switch self {
        case .uploadJournalEntry,
             .createCommunityPostWithImage,
             .createCapsule:
            return AppConstants.Timeout.upload

        case .getAIInsights,
             .getSummary,
             .createCoachSession,
             .createCoachSessionWithJournal,
             .getCoachMessages,
             .sendCoachMessage:
            return AppConstants.Timeout.ai

        default:
            return AppConstants.Timeout.standard
        }
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    private func components() -> (path: String, method: String, body: Data?, isMultipart: Bool) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        switch self {
        // Auth
        case .register(let b):       return ("/auth/register", "POST", try? encoder.encode(b), false)
        case .login(let b):          return ("/auth/login",    "POST", try? encoder.encode(b), false)
        case .refreshToken(let b):   return ("/auth/refresh",  "POST", try? encoder.encode(b), false)
        case .logout(let b):         return ("/auth/logout",   "POST", try? encoder.encode(b), false)
        case .me:                    return ("/auth/me",        "GET",  nil, false)

        // Users
        case .userStats:             return ("/users/me/stats",  "GET", nil, false)
        case .updateProfile(let b):  return ("/users/me",        "PATCH", try? encoder.encode(b), false)

        // Journal
        case .uploadJournalEntry:    return ("/journal/entries", "POST", nil, true)
        case .getJournalEntry(let id):      return ("/journal/entries/\(id)", "GET", nil, false)
        case .getJournalEntryStatus(let id): return ("/journal/entries/\(id)/status", "GET", nil, false)
        case .getJournalEntriesByDate(let d): return ("/journal/entries?date=\(d)", "GET", nil, false)
        case .getRecentJournalEntries(let l): return ("/journal/entries/recent?limit=\(l)", "GET", nil, false)

        // Summary
        case .getSummary(let p, let end):
            var path = "/summary?period=\(p)"
            if let end = end { path += "&endDate=\(end)" }
            return (path, "GET", nil, false)

        // Calendar
        case .getCalendarMonth(let y, let m): return ("/calendar?year=\(y)&month=\(m)", "GET", nil, false)

        // AI Insights
        case .getAIInsights(let p): return ("/ai-insights?period=\(p)", "GET", nil, false)

        // Community
        case .getCommunityFeed(let tab, let page, let size):
            return ("/community/feed?tab=\(tab.rawValue)&page=\(page)&size=\(size)", "GET", nil, false)
        case .getCommunityPost(let id):
            return ("/community/posts/\(id)", "GET", nil, false)
        case .createCommunityPost(let b): return ("/community/posts", "POST", try? encoder.encode(b), false)
        case .createCommunityPostWithImage: return ("/community/posts", "POST", nil, true)
        case .deleteCommunityPost(let id): return ("/community/posts/\(id)", "DELETE", nil, false)
        case .likeCommunityPost(let id):   return ("/community/posts/\(id)/like", "POST", nil, false)
        case .unlikeCommunityPost(let id): return ("/community/posts/\(id)/like", "DELETE", nil, false)
        case .getPostComments(let pid, let page, let size):
            return ("/community/posts/\(pid)/comments?page=\(page)&size=\(size)", "GET", nil, false)
        case .createComment(let pid, let b):
            return ("/community/posts/\(pid)/comments", "POST", try? encoder.encode(b), false)
        case .deleteComment(let pid, let cid):
            return ("/community/posts/\(pid)/comments/\(cid)", "DELETE", nil, false)
        case .followUser(let uid):
            return ("/community/users/\(uid)/follow", "POST", nil, false)
        case .unfollowUser(let uid):
            return ("/community/users/\(uid)/follow", "DELETE", nil, false)
        case .likeComment(let cid):
            return ("/community/comments/\(cid)/like", "POST", nil, false)
        case .unlikeComment(let cid):
            return ("/community/comments/\(cid)/like", "DELETE", nil, false)

        // Achievements
        case .getAchievements: return ("/achievements", "GET", nil, false)

        // Time Capsule
        case .getCapsules:           return ("/capsules",       "GET",    nil, false)
        case .createCapsule:         return ("/capsules",       "POST",   nil, true)
        case .getCapsule(let id):    return ("/capsules/\(id)", "GET",    nil, false)
        case .deleteCapsule(let id): return ("/capsules/\(id)", "DELETE", nil, false)

        // Coach
        case .getCoachSessions(let page, let size):
            return ("/coach/sessions?page=\(page)&size=\(size)", "GET", nil, false)
        case .endCoachSession(let sid):
            return ("/coach/sessions/\(sid)/end", "POST", nil, false)
        case .createCoachSession: return ("/coach/sessions", "POST", nil, false)
        case .createCoachSessionWithJournal(let journalId):
            return ("/coach/sessions", "POST", try? encoder.encode(CreateCoachSessionBody(journalEntryId: journalId)), false)
        case .getCoachMessages(let sid):
            return ("/coach/sessions/\(sid)/messages", "GET", nil, false)
        case .sendCoachMessage(let sid, let b):
            return ("/coach/sessions/\(sid)/messages", "POST", try? encoder.encode(b), false)
        case .deleteCoachSession(let id):
            return ("/coach/sessions/\(id)", "DELETE", nil, false)

        // Goals
        case .getActiveGoals:          return ("/goals",               "GET", nil, false)
        case .getAllGoals:              return ("/goals/all",           "GET", nil, false)
        case .completeGoal(let id):    return ("/goals/\(id)/complete", "PUT", nil, false)
        case .dismissGoal(let id):     return ("/goals/\(id)/dismiss",  "PUT", nil, false)

        // Admin
        case .getAIConfig:          return ("/admin/ai-config", "GET",  nil, false)
        case .updateAIConfig(let b): return ("/admin/ai-config", "POST", try? encoder.encode(b), false)

        // Health
        case .health: return ("/health", "GET", nil, false)
        }
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    /// Multipart form data builder — journal ses yüklemesi için
    func buildMultipartRequest(boundary: String) throws -> URLRequest {
        var request = try asURLRequest()
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        switch self {
        case .uploadJournalEntry(let audioData, let filename, let recordedAt, let durationSeconds):
            request.httpBody = buildJournalMultipart(
                boundary: boundary,
                audioData: audioData,
                filename: filename,
                recordedAt: recordedAt,
                durationSeconds: durationSeconds
            )
        case .createCapsule(let audioData, let filename, let body):
            request.httpBody = buildCapsuleMultipart(
                boundary: boundary,
                audioData: audioData,
                filename: filename,
                body: body
            )
        case .createCommunityPostWithImage(let imageData, let filename, let content, let emoji, let isAnonymous):
            request.httpBody = buildCommunityPostMultipart(
                boundary: boundary,
                imageData: imageData,
                filename: filename,
                content: content,
                emoji: emoji,
                isAnonymous: isAnonymous
            )
        default:
            break
        }

        return request
    }

    private func buildJournalMultipart(boundary: String,
                                       audioData: Data,
                                       filename: String,
                                       recordedAt: String,
                                       durationSeconds: Int) -> Data {
        var data = Data()
        let crlf = "\r\n"

        // Audio field
        data.append("--\(boundary)\(crlf)".utf8Data)
        data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\(crlf)".utf8Data)
        data.append("Content-Type: audio/m4a\(crlf)\(crlf)".utf8Data)
        data.append(audioData)
        data.append(crlf.utf8Data)

        // recordedAt field
        data.append("--\(boundary)\(crlf)".utf8Data)
        data.append("Content-Disposition: form-data; name=\"recordedAt\"\(crlf)\(crlf)".utf8Data)
        data.append("\(recordedAt)\(crlf)".utf8Data)

        // durationSeconds field
        data.append("--\(boundary)\(crlf)".utf8Data)
        data.append("Content-Disposition: form-data; name=\"durationSeconds\"\(crlf)\(crlf)".utf8Data)
        data.append("\(durationSeconds)\(crlf)".utf8Data)

        data.append("--\(boundary)--\(crlf)".utf8Data)
        return data
    }

    private func buildCommunityPostMultipart(boundary: String,
                                              imageData: Data,
                                              filename: String,
                                              content: String?,
                                              emoji: String?,
                                              isAnonymous: Bool) -> Data {
        var data = Data()
        let crlf = "\r\n"

        // image file part
        data.append("--\(boundary)\(crlf)".utf8Data)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\(crlf)".utf8Data)
        data.append("Content-Type: image/jpeg\(crlf)\(crlf)".utf8Data)
        data.append(imageData)
        data.append(crlf.utf8Data)

        // content (caption) — optional
        if let content = content, !content.isEmpty {
            data.append("--\(boundary)\(crlf)".utf8Data)
            data.append("Content-Disposition: form-data; name=\"content\"\(crlf)\(crlf)".utf8Data)
            data.append("\(content)\(crlf)".utf8Data)
        }

        // emoji — optional
        if let emoji = emoji, !emoji.isEmpty {
            data.append("--\(boundary)\(crlf)".utf8Data)
            data.append("Content-Disposition: form-data; name=\"emoji\"\(crlf)\(crlf)".utf8Data)
            data.append("\(emoji)\(crlf)".utf8Data)
        }

        // isAnonymous
        data.append("--\(boundary)\(crlf)".utf8Data)
        data.append("Content-Disposition: form-data; name=\"isAnonymous\"\(crlf)\(crlf)".utf8Data)
        data.append("\(isAnonymous)\(crlf)".utf8Data)

        data.append("--\(boundary)--\(crlf)".utf8Data)
        return data
    }

    private func buildCapsuleMultipart(boundary: String,
                                       audioData: Data?,
                                       filename: String?,
                                       body: CreateCapsuleBody) -> Data {
        var data = Data()
        let crlf = "\r\n"

        if let audioData = audioData, let filename = filename {
            data.append("--\(boundary)\(crlf)".utf8Data)
            data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\(crlf)".utf8Data)
            data.append("Content-Type: audio/m4a\(crlf)\(crlf)".utf8Data)
            data.append(audioData)
            data.append(crlf.utf8Data)
        }

        if let json = try? JSONEncoder().encode(body) {
            data.append("--\(boundary)\(crlf)".utf8Data)
            data.append("Content-Disposition: form-data; name=\"metadata\"\(crlf)".utf8Data)
            data.append("Content-Type: application/json\(crlf)\(crlf)".utf8Data)
            data.append(json)
            data.append(crlf.utf8Data)
        }

        data.append("--\(boundary)--\(crlf)".utf8Data)
        return data
    }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}
