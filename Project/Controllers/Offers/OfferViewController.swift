//
//  OfferViewController.swift
//  Project
//
//  Created by José Guerra on 20-03-23.
//

import Foundation
import UIKit

class OfferViewController: UIViewController, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        print(text)
    }
    
    
    
    // MARK: - Variables
    private var presenter: ListPresenter?
    private var model: [JobOfferModel]?
    
    var jobTitle: String?
    var jobSelected: String?
    
    convenience init(presenter: ListPresenter? = nil) {
        self.init()
        self.presenter = presenter
        self.presenter?.attach(view: self)
    }
    
    
    
    
    // MARK: - Components
    
    let searchController = UISearchController()
    
    
    
    private let offerTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.allowsSelection = true
        tableView.register(OfferCell.self, forCellReuseIdentifier: OfferCell.identifier)
        return tableView
    }()
    

    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        navigationItem.title = self.jobTitle
        
        DispatchQueue.main.async { [weak self] in
            self?.offerTableView.delegate = self
            self?.offerTableView.dataSource = self
        }
        
        self.setUpView()
        self.setupSearchController()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        presenter?.showOffersCategory(type: "\(self.jobSelected!)")
    }
    
    
    // MARK: - Setting UP View
    func setUpView() {
        
        view.addSubview(offerTableView)
        
        offerTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            offerTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            offerTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            offerTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            offerTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
        
    }
    
    
    // MARK: - Methods
    func downloadImageFromInternet(urlFromInternet: String) -> UIImage {
        let url = URL(string: urlFromInternet)!
        let session = URLSession(configuration: .default)
        var imageFinal = UIImage()

        
        let downloadPicTask = session.dataTask(with: url) { (data, response, error) in
            if let e = error {
                print("Error downloading picture: \(e)")
            } else {
                if response is HTTPURLResponse {

                    if let imageData = data {
                        imageFinal = UIImage(data: imageData) ?? UIImage()
                    } else {
                        print("Couldn't get image: Image is nil")
                    }
                } else {
                    print("Couldn't get response code for some reason")
                }
            }
        }

        downloadPicTask.resume()
        return imageFinal
    }
    
}


// MARK: - Search functions
extension OfferViewController {
    
    
    
    private func setupSearchController() {
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.placeholder = "Search with keyword"
        self.navigationItem.searchController = searchController
    }
    
    public func updateSearchController(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        var filteredData: [JobOfferModel]?
        
        DispatchQueue.main.async {
            filteredData = self.model
        }
        
        filteredData = []
        
        if searchText == "" {
            filteredData = self.model
        }
        
        for word in self.model! {
            
            if word.title.uppercased().contains(searchText.uppercased()) {
                filteredData?.append(word)
            }
            
            self.offerTableView.reloadData()
            
        }
    }

}




// MARK: - UITable Protocols

extension OfferViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let offerDetailVC = OfferDetailsViewController()
        offerDetailVC.jobInfo = self.model?[indexPath.row]
        navigationController?.pushViewController(offerDetailVC, animated: true)
        
    }
}


extension OfferViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OfferCell.identifier, for: indexPath) as? OfferCell else {
            fatalError("ERROR: problema con el uitableviewcell")
        }
        
        let offerModel = self.model
        var configuration = UIListContentConfiguration.cell()
        configuration.text = "\(offerModel?[indexPath.row].title ?? "null")"
        
        
        // This line sets up the seniority level of the offer
        var seniorityPlaceholder = String()
        
        self.model?.forEach({ index in
            
            if index.seniority.id == 1 {
                seniorityPlaceholder = "Sin Experiencia"
                
            } else if index.seniority.id == 2 {
                seniorityPlaceholder = "Junior"
                
            } else if index.seniority.id == 3 {
                seniorityPlaceholder = "Semi Senior"
                
            } else if index.seniority.id == 4 {
                seniorityPlaceholder = "Senior"
                
            } else if index.seniority.id == 5 {
                seniorityPlaceholder = "Expert"
                
            } else {
                seniorityPlaceholder = "not specified"
            }
        })
        
        // This line sets up the name of the company
        configuration.secondaryText = "Seniority: \(seniorityPlaceholder) \n\(self.model?[indexPath.row].company.name ?? "null")"
        
        configuration.image = downloadImageFromInternet(urlFromInternet: self.model?[indexPath.row].company.logo ?? "null")
        
        cell.contentConfiguration = configuration
        
        return cell
    }
}


extension OfferViewController: ListControllerProtocol {
    func listSuccess(model: [CompanyModel]) {}
    
    func categorySuccess(model: [CategoryModel]) {}
    
    func offerSuccess(model: [JobOfferModel]) {
        
        self.model = model
        
        DispatchQueue.main.async {
            self.offerTableView.reloadData()
        }
    }
    
    func errorList() {
        let alert = UIAlertController(title: "Error", message: "Something went wrong", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
