//
//  LgoinViewController.swift
//  PracticeForLogin
//
//  Created by Lee on 2023/06/22.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

enum LogInCase: String {
    case apple
    case email
    case facebook
    case google
    case kakao
    case naver
}

final class LoginViewController: UIViewController {
    
    // MARK: - Properties
    
    private let loginView = LoginView()
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addActionToLoginButton()
        self.addActionToSignInButton()
        self.setTextFieldDelegate()
        self.addActionToSNSLoginButtons()
    }
    
    override func loadView() {
        super.loadView()
        self.view = self.loginView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavigationController()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.loginView.endEditing(true)
    }
    
    // MARK: - Heleprs
    
    private func setNavigationController(){
        self.navigationController?.navigationBar.isHidden = true
    }
    
    // MARK: - Email Login part (임시)
    
    private func addActionToLoginButton() {
        self.loginView.loginButton.addTarget(self, action: #selector(moveToMainVC), for: .touchUpInside)
    }
    
    @objc private func moveToMainVC() {
        guard self.loginView.emailTextField.hasText == true && self.loginView.passwordTextField.hasText == true else {
            // 조건에 맞지 않는 텍스트를 입력한 사용자에게 email/password 제대로 입력해달라는 alert.
            return }
        self.loginWithEmail { bool in
            if bool {
                // 로그인 완료되면 메인 화면으로 이동.
                self.present(MainTabBarController(), animated: false)
                UserDefaults.standard.setValue(LogInCase.email.rawValue, forKey: UserDefaultsKey.loginCase)
            } else {
                self.showAlert("사용자 정보 없음", "Email을 확인해주세요.", nil)
            }
        }
    }
    
    // email, password 사용해 로그인
    private func loginWithEmail(_ completion: (Bool) -> Void) {
        guard let email = self.loginView.emailTextField.text, let password = self.loginView.passwordTextField.text else { return }
        print("email \(email), password \(password)")
        // 본래 login api를 통해 로그인 시도 결과값 리턴하는 부분
        guard UserDefaults.standard.value(forKey: UserDefaultsKey.userEmail) as? String == self.loginView.emailTextField.text else {
            print("DEBUG: \(UserDefaults.standard.value(forKey: UserDefaultsKey.userEmail))")
            completion(false)
            return
        }
        completion(true)
    }

    
    // MARK: - SNS Login part
    
    private func addActionToSNSLoginButtons() {
        self.loginView.googleSignInButton.addTarget(self, action: #selector(signInWithGoogle), for: .touchUpInside)
        self.loginView.appleSignInButton.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
        self.loginView.facebookSignInButton.addTarget(self, action: #selector(signInWithFacebook), for: .touchUpInside)
        self.loginView.naverSignInButton.addTarget(self, action: #selector(logInWithNaver), for: .touchUpInside)
        self.loginView.kakaoSignInButton.addTarget(self, action: #selector(logInWithKakao), for: .touchUpInside)
    }
    
        // MARK: - Google sign in

//    let signinConfig = GIDConfiguration.init(clientID: "233574830896-1a2au8pu6htonotrojmgq6fu2bmd1ag9.apps.googleusercontent.com")
    
    @objc private func signInWithGoogle() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil, let signInResult else { return }
            // If sign in succeeded, display the app's main content View.
            
            let user = signInResult.user
            let email = user.profile?.email
            let fullName = user.profile?.name
            // let profileImage = user.profile?.imageURL(withDimension: 320)
            UserDefaults.standard.setValue(true, forKey: UserDefaultsKey.isUserExists)
            UserDefaults.standard.setValue(fullName, forKey: UserDefaultsKey.userName)
            UserDefaults.standard.setValue(email, forKey: UserDefaultsKey.userEmail)
            print("DEBUG: user accessToken \(user.accessToken)")
            print("DEBUG: user idToken \(user.idToken)")
            print("DEBUG: user refreshToken \(user.refreshToken)")
            // 로그인 완료되면 메인 화면으로 이동.
            self.present(MainTabBarController(), animated: false)
            UserDefaults.standard.setValue(LogInCase.google.rawValue, forKey: UserDefaultsKey.loginCase)
        }
    }
    
        // MARK: - Apple Sign In
    @objc private func signInWithApple(){
        guard let window = self.view.window else { return }
        AppleSignInManager.shared.signInWithApple(window: window)
        UserDefaults.standard.setValue(LogInCase.apple.rawValue, forKey: UserDefaultsKey.loginCase)
        
    }
    
        // MARK: - Facebook Sign In
    @objc private func signInWithFacebook() {
        FacebookLoginManager.shared.logInWithFacebook()
        UserDefaults.standard.setValue(LogInCase.facebook.rawValue, forKey: UserDefaultsKey.loginCase)
    }
    
        // MARK: - Naver Log In
    @objc private func logInWithNaver() {
        NaverLoginManager.shared.logIn()
        UserDefaults.standard.setValue(LogInCase.naver.rawValue, forKey: UserDefaultsKey.loginCase)
    }
    
        // MARK: - Kakao Log In
    @objc private func logInWithKakao() {
        // kakaotalk이 설치되어 있을 경우
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                guard error == nil else {
                    print("DEBUG: \(error!)")
                    // 카카오톡이 설치되어 있지만 로그인되지 않은 경우 에러 발생 가능성 존재
                    return
                }
                self?.setUserInfoByKakao()
                print("DEBUG: \(oauthToken?.accessToken)")
            }
        } else {
            // kakaotalk이 설치되어있지 않은 경우 openSafariApi로 연결해 진행
            UserApi.shared.loginWithKakaoAccount { [weak self] oauthToken, error in
                guard error == nil else {
                    print("DEBUG: \(error!)")
                    return
                }
                self?.setUserInfoByKakao()
                print("DEBUG: \(oauthToken?.accessToken)")
                return
            }
        }
    }
    
    func setUserInfoByKakao() {
        UserApi.shared.me { [weak self] user, error in
            guard let email = user?.kakaoAccount?.email else {
                print("DEBUG: kakao email 없음")
                return
            }
            // 수신한 email 서버에 전달
            UserDefaults.standard.setValue(email, forKey: UserDefaultsKey.userEmail)
            UserDefaults.standard.setValue(true, forKey: UserDefaultsKey.isUserExists)
            self?.present(MainTabBarController(), animated: false)
            UserDefaults.standard.setValue(LogInCase.kakao.rawValue, forKey: UserDefaultsKey.loginCase)
        }
    }
    
    // MARK: - Sign In VC로 이동
    
    private func addActionToSignInButton() {
        self.loginView.signInButton.addTarget(self, action: #selector(moveToSignInViewController), for: .touchUpInside)
    }
    
    @objc private func moveToSignInViewController() {
        self.navigationController?.pushViewController(SignInViewController(), animated: true)
    }
}

// MARK: - TextField Delegate
extension LoginViewController: UITextFieldDelegate {
    func setTextFieldDelegate() {
        self.loginView.emailTextField.delegate = self
        self.loginView.passwordTextField.delegate = self
    }
    
    // 후에 textfield값 처리를 위해...
    
}
