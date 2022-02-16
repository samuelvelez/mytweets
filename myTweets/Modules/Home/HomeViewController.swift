//
//  HomeViewController.swift
//  myTweets
//
//  Created by Samuel on 12/1/22.
//

import UIKit
import Simple_Networking
import SVProgressHUD
import NotificationBannerSwift
import AVKit


class HomeViewController: UIViewController {

    //MARK: -IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - properties
    private let cellID = "TweetTableViewCell"
    private var dataSource = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        getPost()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getPost()
    }

    private func getPost(){
        SVProgressHUD.show()
        SN.get(endpoint: Endpoints.getPosts) { (response: SNResultWithEntity<[Post], ErrorResponse>) in
            
            SVProgressHUD.dismiss()
            
            switch response{
            case .success(let posts):
                self.dataSource = posts
                self.tableView.reloadData()
            case .error(error: let error):
                NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger).show()
            case .errorResult(entity: let entity):
                NotificationBanner(title: "Error", subtitle: entity.error, style: .warning).show()
            }
            
        }
        
        
    }
    
    private func setupUI(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
    }
    
    private func deletePostAt(indexPath: IndexPath){
        //1 indicar carga al usuario
        SVProgressHUD.show()
        //2 obtener id del post que vamos a borrar
        let postId = dataSource[indexPath.row].id
        //3 preparamos endpoint para borrar
        let endpoint = Endpoints.delete + postId
        //4 llaamr al endpoint
        SN.delete(endpoint: endpoint) { (response: SNResultWithEntity<GeneralResponse, ErrorResponse>) in
            SVProgressHUD.dismiss()
            
            switch response{
            case .success:
                //1borrar el post del datasource
                self.dataSource.remove(at: indexPath.row)
                //2 borrar la celda de la tabla
                
                self.tableView.deleteRows(at:[indexPath], with: .left)
            case .error(error: let error):
                NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger).show()
            case .errorResult(entity: let entity):
                NotificationBanner(title: "Error", subtitle: entity.error, style: .warning).show()
            }
        }
        
    }
}
//MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Borrar") { _, _ in
            //aqui borramos el tweet
            self.deletePostAt(indexPath: indexPath)
        }
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return dataSource[indexPath.row].author.email != "test@test.com"
    }
}

//MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        if let cell = cell as? TweetTableViewCell{
            //configurar la celda
            cell.setupCellWith(post: dataSource[indexPath.row])
            cell.needsToShowVideo = { url in
                //aqeui abrimos un view controller
                let avPlayer = AVPlayer(url: url)
                let avPlayerController = AVPlayerViewController()
                avPlayerController.player = avPlayer
                
                self.present(avPlayerController, animated: true){
                    avPlayerController.player?.play()
                }
            }
        }
        return cell
    }
}

//MARK: - Navigation
extension HomeViewController{
    
    //este metodo se llamara cuando se haga transiciones entre pantallas solo con storyboards
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        //validar que el segue seal el esperado
        if segue.identifier == "showMap", let mapViewController = segue.destination as? MapViewController{
            // ya sabemos que vamos a la pantalla del map
            mapViewController.posts = dataSource.filter { $0.hasLocation }
            
        }
    }
}
