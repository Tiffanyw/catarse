class PaypalController < ApplicationController
  
  before_filter :initialize_paypal
  
  def pay
    backer = Backer.find params[:id]
    begin
      paypal_response = @paypal.setup(
        paypal_payment(backer),
        success_paypal_url(backer),
        cancel_paypal_url(backer),
        :no_shipping => true
      )
      redirect_to paypal_response.redirect_uri
    #rescue Paypal::Exception::APIError => e
    #  raise "Message: #{e.message}<br/>Response: #{e.response.inspect}<br/>Details: #{e.response.details.inspect}"
    rescue
      flash[:failure] = t('projects.pay.paypal_error')
      return redirect_to back_project_path(backer.project)
    end
  end

  def success
    backer = Backer.find params[:id]
    begin
      details = @paypal.details(params[:token])
      checkout = @paypal.checkout!(
        params[:token],
        details.payer.identifier,
        paypal_payment(backer)
      )
      if checkout.payment_info.first.payment_status == "Completed"
        backer.update_attribute :key, checkout.payment_info.first.transaction_id
        backer.confirm!
        flash[:success] = t('projects.pay.success')
        redirect_to thank_you_path
      else
        flash[:failure] = t('projects.pay.paypal_error')
        return redirect_to back_project_path(backer.project)
      end
    rescue
      flash[:failure] = t('projects.pay.paypal_error')
      return redirect_to back_project_path(backer.project)
    end
  end
  
  def cancel
    backer = Backer.find params[:id]
    flash[:failure] = t('projects.pay.paypal_cancel')
    redirect_to back_project_path(backer.project)
  end

  protected
  
  def initialize_paypal
    # TODO remove the sandbox! when ready
    Paypal.sandbox!
    # TODO remove the sandbox! when ready
    
    @paypal = Paypal::Express::Request.new(
      :username   => 'seller_1316500625_biz_api1.yahoo.com', # Configuration.find_by_name('paypal_username').value,
      :password   => '1316500662', #Configuration.find_by_name('paypal_password').value,
      :signature  => 'Ay0WGeDNE3scjpjgVSFjMHA6ARRFACyjEgEFZfKzqqRzGIEnfyLN0RDx' # Configuration.find_by_name('paypal_signature').value
    )
  end
  
  def paypal_payment(backer)
    Paypal::Payment::Request.new(
      :currency_code => :USD,
      :amount => backer.value,
      :description => t('projects.pay.paypal_description'),
      :items => [{
          :name => backer.project.name,
          :description => t('projects.pay.paypal_description'),
          :amount => backer.value#,
          #:category => :Digital
        }]
    )
  end
  
end
