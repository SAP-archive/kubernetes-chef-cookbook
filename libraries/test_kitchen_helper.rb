module TestKitchenHelper
  def test_kitchen_active?
    !node[cookbook_name]['test_kitchen'].nil?
  end
end
Chef::Recipe.send(:include, TestKitchenHelper)
