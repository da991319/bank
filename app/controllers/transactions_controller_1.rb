class TransactionsController < ApplicationController

  require "faster_csv"
  before_filter :login_required
  
  # GET /transactions
  # GET /transactions.xml
  def index
   
    @transactions_payed = Transaction.paginate :all, :page => params[:page], :per_page => 5, :conditions => [" payed = true OR amount > 0"]
    @transactions_unpayed = Transaction.paginate :all, :page => params[:page], :per_page => 5, :conditions => ["payed = false" ] 
    @last_upload = Transaction.maximum(:created_at)
    session[:subtotal] = 0
 
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transactions }
    end
  end


  # GET /transactions/new
  # GET /transactions/new.xml
  def new
    @transaction = Transaction.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transaction }
    end
  end


  # POST /transactions

  def create
    @CSV = FasterCSV.parse(params[:file],{:headers => true, :write_headers => true})
    
    n = 0
    @CSV.each do |row|
      
     @transaction = Transaction.new({:description => row[4], :amount => row[6], :transaction_date => row[2]})
     
     if @transaction.amount > 0
       
        @transaction.payed = true
        
     end
     if @transaction.save 
      n += 1
     else
      error += @transaction.description + "-" 
     end 
    end
    redirect_to(transactions_path)
    flash[:notice]="CSV Import Successful,  #{n} new records added to data base. "
    
  end

  # PUT /transactions/1
  # PUT /transactions/1.xml
  def update
    @transaction = Transaction.find(params[:id])

    respond_to do |format|
      if @transaction.update_attributes(params[:transaction])
        flash[:notice] = 'Transaction was successfully updated.'
        format.html { redirect_to(@transaction) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @transaction.errors, :status => :unprocessable_entity }
      end
    end
  end

  
  def update_user
    @transaction = Transaction.find(params[:id])
    
    @transaction.user = params[:user]
    @transaction.save
    redirect_to(transactions_path)
  end
  

 def payed
    
    if !request.xml_http_request?
      
      if !params[:payed].nil?
       n = 0
        params[:payed].each  do |transaction| 
          @transaction = Transaction.find(transaction)
          @transaction.payed = true
          @transaction.payed_date = Time.now
          @transaction.payed_by = current_user.login
          @transaction.save
          n += 1
          
       end
       flash[:notice] = "#{n} transaction(s) have been payed"
      else
       flash[:notice] = "Select at least one transaction"
      end
      
      redirect_to transactions_path

    else
      @transaction = Transaction.find(params[:id])
      if params[:checked].eql?("true")
         
        @subtotal = session[:subtotal].to_f + @transaction.amount
        session[:subtotal] = @subtotal
      else
        @subtotal = session[:subtotal].to_f - @transaction.amount
        session[:subtotal] = @subtotal
      end
     
    end
  end
 
end
