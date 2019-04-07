# == Schema Information
#
# Table name: async_processes
#
#  id         :integer          not null, primary key
#  file_hash  :string
#  request    :text
#  rid        :string
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AsyncProcess < ApplicationRecord
end
