/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Receipt : Codable {
	let adam_id : Int?
	let app_item_id : Int?
	let application_version : Int?
	let bundle_id : String?
	let download_id : Int?
	let in_app : [In_app]?
	let original_application_version : String?
	let original_purchase_date : String?
	let original_purchase_date_ms : Int?
	let original_purchase_date_pst : String?
	let receipt_creation_date : String?
	let receipt_creation_date_ms : Int?
	let receipt_creation_date_pst : String?
	let receipt_type : String?
	let request_date : String?
	let request_date_ms : Int?
	let request_date_pst : String?
	let version_external_identifier : Int?

	enum CodingKeys: String, CodingKey {

		case adam_id = "adam_id"
		case app_item_id = "app_item_id"
		case application_version = "application_version"
		case bundle_id = "bundle_id"
		case download_id = "download_id"
		case in_app = "in_app"
		case original_application_version = "original_application_version"
		case original_purchase_date = "original_purchase_date"
		case original_purchase_date_ms = "original_purchase_date_ms"
		case original_purchase_date_pst = "original_purchase_date_pst"
		case receipt_creation_date = "receipt_creation_date"
		case receipt_creation_date_ms = "receipt_creation_date_ms"
		case receipt_creation_date_pst = "receipt_creation_date_pst"
		case receipt_type = "receipt_type"
		case request_date = "request_date"
		case request_date_ms = "request_date_ms"
		case request_date_pst = "request_date_pst"
		case version_external_identifier = "version_external_identifier"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		adam_id = try values.decodeIfPresent(Int.self, forKey: .adam_id)
		app_item_id = try values.decodeIfPresent(Int.self, forKey: .app_item_id)
		application_version = try values.decodeIfPresent(Int.self, forKey: .application_version)
		bundle_id = try values.decodeIfPresent(String.self, forKey: .bundle_id)
		download_id = try values.decodeIfPresent(Int.self, forKey: .download_id)
		in_app = try values.decodeIfPresent([In_app].self, forKey: .in_app)
		original_application_version = try values.decodeIfPresent(String.self, forKey: .original_application_version)
		original_purchase_date = try values.decodeIfPresent(String.self, forKey: .original_purchase_date)
		original_purchase_date_ms = try values.decodeIfPresent(Int.self, forKey: .original_purchase_date_ms)
		original_purchase_date_pst = try values.decodeIfPresent(String.self, forKey: .original_purchase_date_pst)
		receipt_creation_date = try values.decodeIfPresent(String.self, forKey: .receipt_creation_date)
		receipt_creation_date_ms = try values.decodeIfPresent(Int.self, forKey: .receipt_creation_date_ms)
		receipt_creation_date_pst = try values.decodeIfPresent(String.self, forKey: .receipt_creation_date_pst)
		receipt_type = try values.decodeIfPresent(String.self, forKey: .receipt_type)
		request_date = try values.decodeIfPresent(String.self, forKey: .request_date)
		request_date_ms = try values.decodeIfPresent(Int.self, forKey: .request_date_ms)
		request_date_pst = try values.decodeIfPresent(String.self, forKey: .request_date_pst)
		version_external_identifier = try values.decodeIfPresent(Int.self, forKey: .version_external_identifier)
	}

}