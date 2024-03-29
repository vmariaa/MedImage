//
//  DocumentsViewController.swift
//  MedImage
//
//  Created by Vanda S. on 16/06/2022.
//

import UIKit
import CoreData

class DocumentsViewController: UIViewController {

    @IBOutlet weak var documentsTableView: UITableView!
    var searchBar: UISearchBar = UISearchBar()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var sorted: Bool = false
    var sortButton: UIBarButtonItem?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        documentsTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.enablesReturnKeyAutomatically = false
        
        Fetched.filteredPictures = []
        Fetched.fetchedPictures = []
        
        searchBar.delegate = self
        
        documentsTableView.delegate = self
        documentsTableView.dataSource = self
 
        documentsTableView.register(PictureCell.self, forCellReuseIdentifier: "PictureCell")
        
        sortButton = UIBarButtonItem(title: "Sort by date".localized(), style: .done, target: self, action: #selector(sortByDate))

        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPicture)), sortButton!]

        setTableView()
        setSearchBar()
        
        DispatchQueue.global().async {
            for picture in Fetched.pictures {
                Fetched.fetchImagesFromDisk(fileName: picture.photo!) { image in
                    Fetched.fetchedPictures.append(image)
                    Fetched.filteredPictures.append(image)
                }
            }
        }
    }
    
    func setTableView() {
        documentsTableView.tableHeaderView = searchBar
        
        documentsTableView.translatesAutoresizingMaskIntoConstraints = false
        documentsTableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        documentsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        documentsTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        documentsTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        documentsTableView.backgroundColor = .clear
    }
    
    func setSearchBar() {
        searchBar.searchBarStyle = UISearchBar.Style.default
        searchBar.placeholder = " Search...".localized()
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.backgroundColor = .systemBackground
    }
    
    
    //OBJ-C FUNCTIONS
    
    @objc func addPicture() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "NewViewController") as! NewViewController
        Fetched.globalTableView = documentsTableView
        present(vc, animated: true)
    }
    
    @objc func sortByDate() {
        Fetched.filteredPictures = []
        guard let sortButton = sortButton else {
            return
        }
        if sorted == false {
            Fetched.filteredData = Fetched.filteredData.sorted(by: {
                $0.date!.compare($1.date!) == .orderedDescending })
            sortButton.title = "Reset".localized()
        } else {
            Fetched.filteredData = Fetched.filteredData.sorted(by: {
                $0.timestamp!.compare($1.timestamp!) == .orderedDescending
            })
            sortButton.title = "Sort by date".localized()
        }
        sorted = !sorted
        
        for date in Fetched.filteredData {
            Fetched.fetchImagesFromDisk(fileName: date.photo!) { image in
                Fetched.filteredPictures.append(image)
            }
        }
        documentsTableView.reloadData()
    }
}



extension DocumentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Fetched.filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = documentsTableView.dequeueReusableCell(withIdentifier: "PictureCell", for: indexPath) as! PictureCell
        
        let thumbnail = resizedImage(sourceImage: Fetched.filteredPictures[indexPath.row], scaledToWidth: 350)
        cell.documentImageView.image = thumbnail
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Fetched.filteredData[indexPath.row].date!)
        cell.dateLabel.text = dateString
        cell.documentName.text = Fetched.filteredData[indexPath.row].name
        cell.documentName.lineBreakMode = .byTruncatingTail
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as! PreviewViewController
        navigationController?.pushViewController(vc, animated: true)
        print(Fetched.filteredData[indexPath.row])
        vc.selectedImage = Fetched.filteredData[indexPath.row]

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 138
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            context.delete(Fetched.filteredData[indexPath.row])
            
            let index = Fetched.pictures.removeFirst(object: Fetched.filteredData[indexPath.row])
            Fetched.fetchedPictures.remove(at: index!)
            Fetched.filteredPictures.remove(at: indexPath.row)
            Fetched.filteredData.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            do {
                try context.save()
            } catch {
                print("Could not save context after deleting data")
            }
        }
    }
}

extension DocumentsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Fetched.filteredData = []
        Fetched.filteredPictures = []
        
        if searchText == "" {
            Fetched.filteredData = Fetched.pictures
            Fetched.filteredPictures = Fetched.fetchedPictures
            sorted = false
            sortButton!.title = "Sort by date".localized()
        } else {
            for imageObject in Fetched.pictures {
                sorted = false
                sortButton!.title = "Sort by date".localized()
                if imageObject.name!.lowercased().starts(with: searchText.lowercased()) {
                    Fetched.filteredData.append(imageObject)
                    Fetched.fetchImagesFromDisk(fileName: imageObject.photo!) { image in
                        Fetched.filteredPictures.append(image)
                    }
                }
            }
        }
        self.documentsTableView.reloadData()
}
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }    
}
