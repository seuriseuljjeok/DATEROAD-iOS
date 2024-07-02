//
//  LoginViewController.swift
//  DATEROAD-iOS
//
//  Created by 윤희슬 on 7/1/24.
//

import UIKit

import AuthenticationServices

final class LoginViewController: BaseViewController {
    
    // MARK: - UI Properties
    
    private let loginView = LoginView()

    
    // MARK: - Properties
    
    private let loginViewModel = LoginViewModel()
    

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        setAddTarget()
    }
    
    override func setHierarchy() {
        self.view.addSubview(loginView)
    }
    
    override func setLayout() {
        loginView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

}

extension LoginViewController {
    
    func bindViewModel() {
        self.loginViewModel.onLoginSuccess = { [weak self] in
            self?.pushToPointSystemManualVC()
        }
    }
    
    func setAddTarget() {
        self.loginView.kakaoLoginButton.addTarget(self, action: #selector(didTapKakaoLoginButton), for: .touchUpInside)
        self.loginView.appleLoginButton.addTarget(self, action: #selector(didTapAppleLoginButton), for: .touchUpInside)
    }
    
    // TODO: - 추후 뷰컨 변경 예정
    
    func pushToPointSystemManualVC() {
        let pointSystemManualVC = ViewController()
        self.navigationController?.pushViewController(pointSystemManualVC, animated: true)
    }
    
}

extension LoginViewController {
    
    @objc
    func didTapKakaoLoginButton() {
        loginViewModel.checkKakaoInstallation { [weak self] isInstalled in
            if isInstalled {
                self?.loginViewModel.loginWithKakaoApp()
            } else {
                self?.loginViewModel.loginWithKakaoWeb()
            }
        }
    }
    
    @objc
    func didTapAppleLoginButton() {
        let appleProvider = ASAuthorizationAppleIDProvider()
        let request = appleProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        else { return }
        
        self.loginViewModel.loginWithApple(userInfo: credential)

    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        let alert = UIAlertController(title: "로그인 실패", message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .cancel))
        present(alert, animated: true)
    }
    
}
