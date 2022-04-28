//
//  Response.swift
//  vkAPI
//
//  Created by sergey on 20.02.2018.
//  Copyright © 2018 sergey. All rights reserved.
//

import Foundation

struct Response: Decodable {
	var response: Response2
	init() {response = Response2()}
}
struct Response2: Decodable {
	let count: Int
	var items: [User]
	init() {count = 0;items = []}
}
struct User: Decodable {
	let id: Int
	let first_name: String
	let last_name: String
	let online: Int
	let photo_100: URL
}

struct UsersGet: Decodable {
	let response: [Member]
}

struct Member: Decodable {
	let id: Int
	let first_name,last_name: String
	let photo_max: URL
}
