# == Schema Information
#
# Table name: watermarks
#
#  id         :integer          not null, primary key
#  fragment   :string
#  key        :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#

class Watermark < ApplicationRecord
end
