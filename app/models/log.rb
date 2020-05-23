# == Schema Information
#
# Table name: logs
#
#  id         :integer          not null, primary key
#  item       :text
#  read_hash  :string
#  receipt    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Log < ApplicationRecord
end
