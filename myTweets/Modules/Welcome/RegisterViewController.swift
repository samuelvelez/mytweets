//
//  RegisterViewController.swift
//  myTweets
//
//  Created by Samuel on 12/1/22.
//

import UIKit
import NotificationBannerSwift
import Simple_Networking
import SVProgressHUD

class RegisterViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
    }
    
    @IBAction func registerButtonAction(){
        view.endEditing(true)
        performRegister()
    }
    
    private func setupUI(){
        registerButton.layer.cornerRadius = 25
        
    }
    
    private func performRegister(){
        guard let email = emailTextField.text, !email.isEmpty else {
            NotificationBanner(title: "¡Error!", subtitle: "Debes especificar un correo", style: .warning).show()
            return
        }
        guard let name = nameTextField.text, !name.isEmpty else {
            NotificationBanner(title: "¡Error!", subtitle: "Debes especificar un nombre", style: .warning).show()
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else
        {
            NotificationBanner(title: "¡Error!", subtitle: "Debes especificar una contraseña", style: .warning).show()
            
            return
        }
        //performSegue(withIdentifier: "showHome", sender: nil)
        //crear request
        let request = RegisterRequest(email: email, password: password, names: name)
        
        //iniciamos la carga
        SVProgressHUD.show()
        
        //llamar a libreria de red
        SN.post(endpoint: Endpoints.register, model: request) { (response: SNResultWithEntity<LoginResponse, ErrorResponse>) in
            SVProgressHUD.dismiss()
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
        
        
    }

}
