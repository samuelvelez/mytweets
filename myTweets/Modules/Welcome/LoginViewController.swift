//
//  LoginViewController.swift
//  myTweets
//
//  Created by Samuel on 12/1/22.
//

import UIKit
import NotificationBannerSwift
import Simple_Networking
import SVProgressHUD

class LoginViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //MARK: - IBActions
    @IBAction func loginButtonAction(){
        view.endEditing(true)
        performLogin()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
    }
    
    //MARK: - Private Methods
    private func setupUI(){
        loginButton.layer.cornerRadius = 25
        
        loginButton.backgroundColor = UIColor.customGreen
    }
    
    private func performLogin(){
        guard let email = emailTextField.text, !email.isEmpty else {
            NotificationBanner(title: "¡Error!", subtitle: "Debes especificar un correo", style: .warning).show()
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else
        {
            NotificationBanner(title: "¡Error!", subtitle: "Debes especificar una contraseña", style: .warning).show()
            
            return
        }
        //crear request
        let request = LoginRequest(email: email, password: password)
        
        //iniciamos la carga
        SVProgressHUD.show()
        
        //llamar a libreria de red
        SN.post(endpoint: Endpoints.login, model: request) { (response: SNResultWithEntity<LoginResponse, ErrorResponse>) in
            
            switch response{
            case .success(let user):
                self.performSegue(withIdentifier: "showHome", sender: nil)
                SimpleNetworking.setAuthenticationHeader(prefix: "", token: user.token)
            case .error(error: let error):
                NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger).show()
            case .errorResult(entity: let entity):
                NotificationBanner(title: "Error", subtitle: entity.error, style: .warning).show()
            }
            
        }
        
        SVProgressHUD.dismiss()
        
        //performSegue(withIdentifier: "showHome", sender: nil)
    }
}

extension UIColor{
    static let customGreen: UIColor = {
        if #available(iOS 13.0, *){
            return UIColor { (trait: UITraitCollection) -> UIColor in
                if trait.userInterfaceStyle == .dark {
                    //dark mode
                    return .white
                }else{
                    //light mode
                    return .green
                }
            }
        }else{
            //aqui es mejor de ios 13
            return .green
        }
    }()
}
