//
//  ViewController.swift
//  vkAPI
//
//  Created by sergey on 18.02.2018.
//  Copyright © 2018 sergey. All rights reserved.
//

import UIKit

var userList: [String:(User,Bool)] = [:]

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {

	@IBOutlet weak var userImage: UIImageView!
	@IBOutlet weak var userFName: UILabel!
	@IBOutlet weak var userLName: UILabel!
	
	@IBOutlet weak var usersTable: UITableView!
	@IBOutlet weak var friendsCount: UILabel!
	@IBOutlet weak var option: UISegmentedControl!
	@IBOutlet weak var refreshButton: UIButton!
	@IBAction func optionChanged() {
		let friends = self.friends.response.items
		switch self.option.selectedSegmentIndex {
		case 0:
			self.friendsManager = self.friends
		case 1:
			self.friendsManager.response.items = friends.compactMap {user -> User? in if user.online == 1 { return user }
				return nil
			}
		default:
			self.friendsManager.response.items = friends.compactMap {user -> User? in if user.online == 0 { return user }
				return nil
			}
		}
		if self.friendsCount.text != "user deactivated" {
			self.friendsCount.text = self.friendsManager.response.items.count == 1 ? "1 Friend":"\(self.friendsManager.response.items.count) Friends"
		}
		for user in userList {
			userList[user.key]!.1 = true
		}
		self.usersTable.reloadData()
	}
	var currentID: Int = 20430470
    @IBAction func refresh() {
        vkRequest(currentID)
    }
    @IBAction func findById(_ sender: UITextField) {
        if let id = Int(sender.text!), id > 0 {
            vkRequest(id)
        }
    }
	
	var friends = Response()
	var friendsManager = Response()
	
	func vkRequest(_ id:Int) {
		let url = URL(string: "https://api.vk.com/method/friends.get?user_id=\(id)&fields=first_name,last_name,online,photo_100&v=5.131&access_token=\(access_token)")!
		URLSession.shared.dataTask(with: url) {(data,_,error) in
			guard error == nil else {
				DispatchQueue.main.async {
					self.friendsCount.text = error!.localizedDescription
					self.friendsCount.font = self.friendsCount.font.withSize(12)
					for subview in self.view.subviews {
						subview.isUserInteractionEnabled = false
					}
				}
				return
			}
			guard let data = data else {return}
			do {
				self.friends = try JSONDecoder().decode(Response.self, from: data)
				self.friendsManager = self.friends
                
				for user in self.friends.response.items {
					userList.updateValue((user,true), forKey: user.first_name+" "+user.last_name)
				}
                
				DispatchQueue.main.async {
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					self.usersTable.reloadData()
					self.option.selectedSegmentIndex = 0
					self.friendsCount.text = self.friends.response.count == 1 ? "1 Friend":"\(self.friendsManager.response.items.count) Friends"
					self.usersTable.allowsSelection = true
					self.option.isUserInteractionEnabled = true
					self.refreshButton.isUserInteractionEnabled = true
				}
			} catch {
				DispatchQueue.main.async {
					self.friendsCount.text = "user deactivated"
					self.usersTable.allowsSelection = true
					self.option.isUserInteractionEnabled = true
					self.refreshButton.isUserInteractionEnabled = false
					self.friendsManager = Response()
					self.friends = Response()
					self.usersTable.reloadData()
				}
			}
		}.resume()
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		// 2nd part
		let userURL = URL(string: "https://api.vk.com/method/users.get?user_ids=\(id)&fields=photo_max&v=5.131&access_token=\(access_token)")!
		URLSession.shared.dataTask(with: userURL) { data,_,error in
			guard error == nil else {
				DispatchQueue.main.async {
					self.friendsCount.text = error!.localizedDescription
					self.friendsCount.font = self.friendsCount.font.withSize(12)
					for subview in self.view.subviews {
						subview.isUserInteractionEnabled = false
					}
				}
				return
			}
			guard let data = data else {return}
			var member = UsersGet(response: [])
			do {
				member = try JSONDecoder().decode(UsersGet.self, from: data)
				self.currentID = member.response.first!.id
				DispatchQueue.main.async {
					self.userFName.text = member.response[0].first_name
					self.userLName.text = member.response[0].last_name
					URLSession.shared.dataTask(with: member.response[0].photo_max) { data,_,_ in
						guard let data = data else {return}
						DispatchQueue.main.async {
							UIApplication.shared.isNetworkActivityIndicatorVisible = false
							self.userImage.image = UIImage(data: data)
							self.userImage.layer.cornerRadius = 50
//user image border
//                            self.userImage.layer.borderWidth = 3
//                            self.userImage.layer.borderColor = UIColor(red: 76/255.0, green: 117/255.0, blue: 163/255.0, alpha: 1).cgColor
							self.userImage.clipsToBounds = true
						}
					}.resume()
				}
			} catch let err {
				print(err)
			}
		}.resume()
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
	}

    override func viewDidLoad() {
		super.viewDidLoad()
		friendsCount.text = ""
		userFName.text = ""
		userLName.text = ""
		vkRequest(20430470)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return friendsManager.response.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let name = friendsManager.response.items[indexPath.row].first_name+" "+friendsManager.response.items[indexPath.row].last_name
		if let _ = userList[name] {
			let cell = usersTable.dequeueReusableCell(withIdentifier: "user cell")! as! UserCell
			let friends = friendsManager.response.items
			cell.userName.text = name//"\(friends[indexPath.row].first_name) \(friends[indexPath.row].last_name)"
			URLSession.shared.dataTask(with: friends[indexPath.row].photo_100) { data,_,_ in
				guard let data = data else {return}
				let image = UIImage(data: data)
				DispatchQueue.main.async {
					cell.img.image = image
					cell.img.layer.cornerRadius = 25
					cell.img.clipsToBounds = true
				}
			}.resume()
			return cell
		} else {
			let cell = usersTable.dequeueReusableCell(withIdentifier: "info cell")!
			//let friends = friendsManager.response.items
			cell.textLabel?.text = name//"\(friends[indexPath.row].first_name) \(friends[indexPath.row].last_name)"
			return cell
		}
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		/*
		Main functionality disabled ->>
		
		tableView.allowsSelection = false
		option.isUserInteractionEnabled = false
        refreshButton.isUserInteractionEnabled = false
		vkRequest(friendsManager.response.items[indexPath.row].id)
		*/
		tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.reuseIdentifier == "info cell" {   //21.01.2020
            var strToCopy = cell?.textLabel?.text
            strToCopy?.removeLast()
            strToCopy?.removeFirst(4)
            UIPasteboard.general.string = strToCopy
        }
        
		let range = friendsManager.response.items.index(after: indexPath.row)...friendsManager.response.items.index(after: indexPath.row)//+1)
		let name = friendsManager.response.items[indexPath.row].first_name+" "+friendsManager.response.items[indexPath.row].last_name
		if let info = userList[name], info.1 {
			userList[name]!.1 = !userList[name]!.1
			tableView.beginUpdates()
			let id = User(id: -1, first_name: "id: \(info.0.id)", last_name: "", online: -1, photo_100: URL(string: "https://apple.com")!)
			//let online = User(id: -1, first_name: "photo: \(info.0.photo_100)", last_name: "", online: -1, photo_100: URL(string: "https://apple.com")!)
			let insertingElements = [id]//,online]
			friendsManager.response.items.insert(contentsOf: insertingElements, at: friendsManager.response.items.index(after: indexPath.row))
			let indexPaths = range.map {return IndexPath(row: $0, section: 0)}
			tableView.insertRows(at: indexPaths, with: .automatic)
			tableView.endUpdates()
		} else if let info = userList[name], !info.1 {
			userList[name]!.1 = !userList[name]!.1
			tableView.beginUpdates()
			friendsManager.response.items.removeSubrange(range)
			let indexPaths = range.map {return IndexPath(row: $0, section: 0)}
			tableView.deleteRows(at: indexPaths, with: .automatic)
			tableView.endUpdates()
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let name = friendsManager.response.items[indexPath.row].first_name+" "+friendsManager.response.items[indexPath.row].last_name
		if let _ = userList[name] {
			return 53
		} else {
			return 44
		}
	}

}
