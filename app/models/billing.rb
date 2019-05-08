# == Schema Information
#
# Table name: billings
#
#  id                :integer          not null, primary key
#  buyer             :string
#  buyer_address     :string
#  buyer_signature   :text
#  offer_price       :float
#  offer_timestamp   :datetime
#  payment_address   :string
#  payment_method    :string
#  payment_price     :float
#  payment_timestamp :datetime
#  request           :text
#  seller            :string
#  seller_signature  :text
#  uid               :string
#  usage_policy      :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  buyer_pubkey_id   :string
#  seller_pubkey_id  :string
#

class Billing < ApplicationRecord
end
