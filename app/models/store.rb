# == Schema Information
#
# Table name: stores
#
#  id         :integer          not null, primary key
#  item       :text
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  prov_id    :integer
#

class Store < ApplicationRecord
end
