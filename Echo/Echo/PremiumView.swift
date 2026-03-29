import SwiftUI

struct PremiumView: View {
    @Binding var selectedTab: String
    @State private var selectedPlan: String = "yearly"
    @State private var showCloseButton = true
    @State private var isMenuOpen = false
    
    var body: some View {
        ZStack {
            Color(red: 0.133, green: 0.114, blue: 0.063)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Hero Section
                VStack(alignment: .leading, spacing: 0) {
                    // Close Button
                    HStack {
                        Button(action: { isMenuOpen.toggle() }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                        .background(Color(red: 0.149, green: 0.098, blue: 0.196))
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.2))
                                .cornerRadius(9999)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    // Icon and Title
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.2), lineWidth: 1)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.2),
                                            Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.15), radius: 15)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color(red: 0.933, green: 0.741, blue: 0.169))
                        }
                        
                        Text("Unlock Full Insight")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Analyze your emotional journey with\ndeep AI intelligence.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 80)
                }
                .frame(height: 320)
                .background(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 0.400, green: 0.300, blue: 0.100).opacity(0.6), location: 0),
                            .init(color: Color(red: 0.133, green: 0.114, blue: 0.063), location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Features List
                        VStack(spacing: 12) {
                            FeatureItemView(
                                icon: "mic.fill",
                                title: "Unlimited Recordings",
                                subtitle: "Capture every moment without limits"
                            )
                            
                            FeatureItemView(
                                icon: "brain.head.profile",
                                title: "Deep AI Analysis",
                                subtitle: "Weekly insights into your habits"
                            )
                            
                            FeatureItemView(
                                icon: "square.grid.2x2",
                                title: "Emotional Heatmaps",
                                subtitle: "Visualize your mood trends"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Plan Selection
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("Monthly")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedPlan == "monthly" ? .white : Color(red: 0.612, green: 0.639, blue: 0.686))
                                
                                Spacer()
                                
                                Text("Yearly")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedPlan == "yearly" ? .white : Color(red: 0.612, green: 0.639, blue: 0.686))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.098, green: 0.063, blue: 0.133))
                            .cornerRadius(9999)
                            .onTapGesture { selectedPlan = "monthly" }
                            
                            HStack(spacing: 12) {
                                // Monthly Plan
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        if selectedPlan == "monthly" {
                                            Circle()
                                                .fill(Color(red: 0.933, green: 0.741, blue: 0.169))
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.black)
                                                )
                                        } else {
                                            Circle()
                                                .strokeBorder(Color(red: 0.612, green: 0.639, blue: 0.686), lineWidth: 1.5)
                                                .frame(width: 20, height: 20)
                                        }
                                        
                                        Text("Monthly")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    Text("Flexible plan")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    
                                    Text("₹99")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("/mo")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(red: 0.098, green: 0.063, blue: 0.133))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            selectedPlan == "monthly" ? Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.3) : Color(red: 0.612, green: 0.639, blue: 0.686).opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                                .onTapGesture { selectedPlan = "monthly" }
                                
                                // Yearly Plan (Best Value)
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        if selectedPlan == "yearly" {
                                            Circle()
                                                .fill(Color(red: 0.933, green: 0.741, blue: 0.169))
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.black)
                                                )
                                        } else {
                                            Circle()
                                                .strokeBorder(Color(red: 0.612, green: 0.639, blue: 0.686), lineWidth: 1.5)
                                                .frame(width: 20, height: 20)
                                        }
                                        
                                        Text("Yearly")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("BEST VALUE")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(0.5)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(red: 0.933, green: 0.741, blue: 0.169))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text("Save 20%")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 0.933, green: 0.741, blue: 0.169))
                                    
                                    Text("₹999")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 0.933, green: 0.741, blue: 0.169))
                                    
                                    Text("/yr")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(red: 0.098, green: 0.063, blue: 0.133))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            selectedPlan == "yearly" ? Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.3) : Color(red: 0.612, green: 0.639, blue: 0.686).opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                                .onTapGesture { selectedPlan = "yearly" }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // CTA Button
                        Button(action: {}) {
                            Text("Start Free Trial")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.933, green: 0.741, blue: 0.169))
                                .foregroundColor(.black)
                                .cornerRadius(9999)
                        }
                        .padding(.horizontal, 20)
                        
                        // Trial Info
                        Text("7-day free trial, then ₹999/year. Cancel anytime.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Footer Links
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Text("Restore Purchase")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            }
                            
                            Text("•")
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            
                            Button(action: {}) {
                                Text("Terms of Service")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            }
                            
                            Text("•")
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            
                            Button(action: {}) {
                                Text("Privacy Policy")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 32)
                }
            }
            
            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }
}

struct FeatureItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.933, green: 0.741, blue: 0.169))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.933, green: 0.741, blue: 0.169).opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686).opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.933, green: 0.741, blue: 0.169))
        }
        .padding(13)
        .background(Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.05), lineWidth: 1)
        )
    }
}
