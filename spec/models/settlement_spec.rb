# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Settlement do
  fixtures :users, :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions
  set_fixture_class  :accounts => Account::Base

  before do
    @current_user = users(:taro)
    
    @deal = @current_user.general_deals.build(:summary => '貸した',
      :date => {:year => '2010', :month => '5', :day => '5'},
      :debtor_entries_attributes => [{:account_id => :taro_hanako.to_id, :amount => 3000}],
      :creditor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => -3000}]
    )
    @deal.save!
    @settlement = @current_user.settlements.build(
      :account_id => :taro_hanako.to_id.to_s,
      :name => 'テスト精算2010-5',
      :description => '',
      :result_partner_account_id => :taro_bank.to_id.to_s,
      :deal_ids => {@deal.id.to_s => '1'},
      :result_date => Date.new(2010, 6, 30)
    )
    @settlement.save!
  end
  describe "submit" do
    it "成功する" do
      expect {@settlement.submit}.not_to raise_error(RuntimeError)
      @settlement.reload
      @settlement.submitted_settlement.should_not be_nil
    end
    context "連携がすべてきれたentryの含まれた精算で" do
      before do
        users(:hanako).deals.destroy_all
      end
      it "成功する" do
        @settlement.submit
        @settlement.reload
        @settlement.submitted_settlement.should_not be_nil
      end
    end
    context "結果の連携だけがきれたentryの含まれた精算で" do
      before do
        users(:hanako).deals.
            select("deals.*"). # avoid readonly
            joins("inner join account_entries on account_entries.deal_id = deals.id").
            where("account_entries.summary = ?", 'テスト精算2010-5').first.destroy
      end
      it "成功する" do
        @settlement.submit
        @settlement.reload
        @settlement.submitted_settlement.should_not be_nil
      end
    end
  end
end