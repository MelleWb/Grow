/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Latest_receipt_info : Codable {
	let quantity : String?
	let product_id : String?
	let transaction_id : String?
	let original_transaction_id : String?
	let purchase_date : String?
	let purchase_date_ms : String?
	let purchase_date_pst : String?
	let original_purchase_date : String?
	let original_purchase_date_ms : String?
	let original_purchase_date_pst : String?
	let expires_date : String?
	let expires_date_ms : String?
	let expires_date_pst : String?
	let web_order_line_item_id : String?
	let is_trial_period : String?
	let is_in_intro_offer_period : String?
	let subscription_group_identifier : String?

	enum CodingKeys: String, CodingKey {

		case quantity = "quantity"
		case product_id = "product_id"
		case transaction_id = "transaction_id"
		case original_transaction_id = "original_transaction_id"
		case purchase_date = "purchase_date"
		case purchase_date_ms = "purchase_date_ms"
		case purchase_date_pst = "purchase_date_pst"
		case original_purchase_date = "original_purchase_date"
		case original_purchase_date_ms = "original_purchase_date_ms"
		case original_purchase_date_pst = "original_purchase_date_pst"
		case expires_date = "expires_date"
		case expires_date_ms = "expires_date_ms"
		case expires_date_pst = "expires_date_pst"
		case web_order_line_item_id = "web_order_line_item_id"
		case is_trial_period = "is_trial_period"
		case is_in_intro_offer_period = "is_in_intro_offer_period"
		case subscription_group_identifier = "subscription_group_identifier"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		quantity = try values.decodeIfPresent(String.self, forKey: .quantity)
		product_id = try values.decodeIfPresent(String.self, forKey: .product_id)
		transaction_id = try values.decodeIfPresent(String.self, forKey: .transaction_id)
		original_transaction_id = try values.decodeIfPresent(String.self, forKey: .original_transaction_id)
		purchase_date = try values.decodeIfPresent(String.self, forKey: .purchase_date)
		purchase_date_ms = try values.decodeIfPresent(String.self, forKey: .purchase_date_ms)
		purchase_date_pst = try values.decodeIfPresent(String.self, forKey: .purchase_date_pst)
		original_purchase_date = try values.decodeIfPresent(String.self, forKey: .original_purchase_date)
		original_purchase_date_ms = try values.decodeIfPresent(String.self, forKey: .original_purchase_date_ms)
		original_purchase_date_pst = try values.decodeIfPresent(String.self, forKey: .original_purchase_date_pst)
		expires_date = try values.decodeIfPresent(String.self, forKey: .expires_date)
		expires_date_ms = try values.decodeIfPresent(String.self, forKey: .expires_date_ms)
		expires_date_pst = try values.decodeIfPresent(String.self, forKey: .expires_date_pst)
		web_order_line_item_id = try values.decodeIfPresent(String.self, forKey: .web_order_line_item_id)
		is_trial_period = try values.decodeIfPresent(String.self, forKey: .is_trial_period)
		is_in_intro_offer_period = try values.decodeIfPresent(String.self, forKey: .is_in_intro_offer_period)
		subscription_group_identifier = try values.decodeIfPresent(String.self, forKey: .subscription_group_identifier)
	}

}
