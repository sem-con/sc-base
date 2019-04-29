# == Schema Information
#
# Table name: async_processes
#
#  id         :integer          not null, primary key
#  error_list :text
#  file_hash  :string
#  file_list  :text
#  request    :text
#  rid        :string
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  store_id   :integer
#

class AsyncProcess < ApplicationRecord
end
