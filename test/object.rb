#  +-------------------------------------------------------------------------
#  | Copyright (C) 2016 Yunify, Inc.
#  +-------------------------------------------------------------------------
#  | Licensed under the Apache License, Version 2.0 (the "License");
#  | you may not use this work except in compliance with the License.
#  | You may obtain a copy of the License in the LICENSE file, or at:
#  |
#  | http://www.apache.org/licenses/LICENSE-2.0
#  |
#  | Unless required by applicable law or agreed to in writing, software
#  | distributed under the License is distributed on an "AS IS" BASIS,
#  | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  | See the License for the specific language governing permissions and
#  | limitations under the License.
#  +-------------------------------------------------------------------------

require 'json'
require 'digest'
require 'net/http'

require 'qingstor/sdk'

# ----------------------------------------------------------------------------

bucket = nil

the_object_key = nil
the_copy_object_key = nil
the_move_object_key = nil

When(/^put object with key "([^"]*)"$/) do |object_key|
  bucket = @qs_service.bucket @test_config[:bucket_name], @test_config[:zone]
  raise if bucket.nil?

  the_object_key = object_key
  system 'dd if=/dev/zero of=/tmp/sdk_bin bs=1m count=1'
  @put_object_output = bucket.put_object(
    the_object_key,
    body: File.open('/tmp/sdk_bin'),
  )
  system 'rm -f /tmp/sdk_bin'
end

Then(/^put object status code is (\d+)$/) do |status_code|
  raise unless @put_object_output[:status_code].to_s == status_code
end

When(/^copy object with key "([^"]*)"$/) do |object_key|
  the_copy_object_key = object_key
  @put_the_copy_object_output = bucket.put_object(
    the_copy_object_key,
    x_qs_copy_source: "/#{@test_config[:bucket_name]}/#{the_object_key}",
  )
end

Then(/^copy object status code is (\d+)$/) do |status_code|
  raise unless @put_the_copy_object_output[:status_code].to_s == status_code
end

When(/^move object with key "([^"]*)"$/) do |object_key|
  the_move_object_key = object_key
  @put_the_move_object_output = bucket.put_object(
    the_move_object_key,
    x_qs_move_source: "/#{@test_config[:bucket_name]}/#{the_copy_object_key}",
  )
end

Then(/^move object status code is (\d+)$/) do |status_code|
  raise unless @put_the_move_object_output[:status_code].to_s == status_code
end

# ----------------------------------------------------------------------------

When(/^get object$/) do
  @get_object_output = bucket.get_object the_object_key
end

Then(/^get object status code is (\d+)$/) do |status_code|
  raise unless @get_object_output[:status_code].to_s == status_code
end

Then(/^get object content length is (\d+)$/) do |length|
  raise unless @get_object_output[:body].length.to_s == length
end

When(/^get object with content type "([^"]*)"$/) do |content_type|
  @get_object_output = bucket.get_object the_object_key,
                                         response_content_type: content_type
end

Then(/^get object content type is "([^"]*)"$/) do |content_type|
  raise unless @get_object_output[:content_type] == content_type
end

When(/^get object with query signature$/) do
  @get_object_request = bucket.get_object_request the_object_key
  @get_object_request.input[:request_headers][:'Content-Type'] = ''
  @get_object_request.sign_query 10
  @get_object_request.build
end

Then(/^get object with query signature content length is (\d+)$/) do |length|
  result = Net::HTTP.get URI.parse @get_object_request.request_url
  raise unless result.length.to_s == length
end

# ----------------------------------------------------------------------------

When(/^head object$/) do
  @head_object_output = bucket.head_object the_object_key
end

Then(/^head object status code is (\d+)$/) do |status_code|
  raise unless @head_object_output[:status_code].to_s == status_code
end

# ----------------------------------------------------------------------------

When(/^options object with method "([^"]*)" and origin "([^"]*)"$/) do |method, origin|
  @options_object_output = bucket.options_object(
    the_object_key,
    access_control_request_method: method,
    origin:                        origin,
  )
end

Then(/^options object status code is (\d+)$/) do |status_code|
  raise unless @options_object_output[:status_code].to_s == status_code
end

# ----------------------------------------------------------------------------

When(/^delete object$/) do
  @delete_object_output = bucket.delete_object the_object_key
end

Then(/^delete object status code is (\d+)$/) do |status_code|
  raise unless @delete_object_output[:status_code].to_s == status_code
end

When(/^delete the move object$/) do
  @delete_the_move_object_output = bucket.delete_object the_move_object_key
end

Then(/^delete the move object status code is (\d+)$/) do |status_code|
  raise unless @delete_the_move_object_output[:status_code].to_s == status_code
end
