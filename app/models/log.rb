# == Schema Information
#
# Table name: logs
#
#  id         :integer          not null, primary key
#  item       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Log < ApplicationRecord
end
