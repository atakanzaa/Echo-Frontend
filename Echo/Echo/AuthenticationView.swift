import SwiftUI

struct AuthenticationView: View {
    @State private var isSigningUp    = false
    @State private var email          = ""
    @State private var password       = ""
    @State private var displayName    = ""
    @State private var confirmPassword = ""
    @State private var showPassword   = false
    @State private var agreeToTerms   = false

    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject  private var appState: AppState

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo Section
                        VStack(spacing: 32) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.498, green: 0.075, blue: 0.929),
                                                Color(red: 0.231, green: 0.510, blue: 0.961)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 96, height: 96)
                                    .shadow(color: Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.2), radius: 15)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text(isSigningUp ? "Create Account" : "Welcome back")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 0) {
                                    Text("Your voice, your journey. Capture")
                                    Text("your thoughts and track your")
                                    Text("growth.")
                                }
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 48)
                        .padding(.bottom, 24)
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if isSigningUp {
                            // Sign Up Form
                            VStack(spacing: 16) {
                                // Display Name Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))

                                    TextField("Your name", text: $displayName)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                                        .cornerRadius(12)
                                }

                                // Email Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))

                                    TextField("Enter your email", text: $email)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                                        .cornerRadius(12)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                
                                // Password Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    
                                    HStack {
                                        if showPassword {
                                            TextField("Enter password", text: $password)
                        .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(.white)
                                        } else {
                                            SecureField("Enter password", text: $password)
                        .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Button(action: { showPassword.toggle() }) {
                                            Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                                    .cornerRadius(12)
                                }
                                
                                // Confirm Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    
                                    SecureField("Confirm password", text: $confirmPassword)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                                        .cornerRadius(12)
                                }
                                
                                // Terms Agreement
                                HStack(spacing: 8) {
                                    Button(action: { agreeToTerms.toggle() }) {
                                        Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    }
                                    
                                    VStack(spacing: 0) {
                                        Text("I agree to the ")
                                        + Text("Terms of Service").foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                        + Text(" and ")
                                        + Text("Privacy Policy").foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    }
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        // Social Login Buttons
                        VStack(spacing: 12) {
                            if isSigningUp {
                                Button {
                                    Task {
                                        await viewModel.register(
                                            email: email,
                                            password: password,
                                            displayName: displayName
                                        )
                                    }
                                } label: {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Create Account")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    .foregroundColor(.white)
                                    .cornerRadius(9999)
                                }
                                .disabled(viewModel.isLoading || !agreeToTerms)
                                .padding(.vertical, 8)
                            }
                            
                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white)
                                .foregroundColor(.black)
                                .cornerRadius(9999)
                            }
                            
                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.098, green: 0.063, blue: 0.133))
                                .foregroundColor(.white)
                                .cornerRadius(9999)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9999)
                                        .strokeBorder(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            if !isSigningUp {
                                HStack {
                                    Text("Or")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)

                                // Email + Password Login
                                VStack(spacing: 12) {
                                    TextField("Email", text: $email)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                                        .cornerRadius(12)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)

                                    SecureField("Password", text: $password)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                                        .cornerRadius(12)

                                    Button {
                                        Task { await viewModel.login(email: email, password: password) }
                                    } label: {
                                        HStack {
                                            if viewModel.isLoading {
                                                ProgressView().tint(.white)
                                            } else {
                                                Text("Sign in with email")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                        .background(Color(red: 0.098, green: 0.063, blue: 0.133))
                                        .cornerRadius(9999)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 9999)
                                                .strokeBorder(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .disabled(viewModel.isLoading)
                                }
                            }
                        }
                        
                        // Sign Up / Log In Toggle
                        HStack(spacing: 4) {
                            Text(isSigningUp ? "Already have an account? " : "Don't have an account? ")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            
                            Button(action: { isSigningUp.toggle() }) {
                                Text(isSigningUp ? "Log in" : "Sign up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        
                        // Terms & Privacy Links
                        HStack(spacing: 16) {
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
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}
