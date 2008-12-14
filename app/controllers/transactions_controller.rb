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
    n = 0
    m = 0
    if !params[:file].nil?
      @CSV = FasterCSV.parse(params[:file],{:headers => true, :write_headers => true})
    
   
      @CSV.each do |row|
     
        transaction = Transaction.find(:all, :conditions => ["description = ? AND amount = ? AND transaction_date = ?", row[4],row[6],row[2]], :select => 'id')
        if transaction.empty?
          @transaction = Transaction.new({:description => row[4], :amount => row[6], :transaction_date => row[2]})
     
          if @transaction.amount > 0
       
            @transaction.payed = true
        
          end
          if @transaction.save
            n += 1
          else
            m += 1
          end
   

        else
          m += 1

        end
      end
      message = "CSV Import Successful,  #{n} new records added to data base. #{m} treansaction(s) failed or already exist"
    else
      # @transaction = Transaction.new({:description => params[:description], :amount =>params[:amount], :transaction_date => params[:date]})
      
      @transaction = Transaction.new(params[:transaction])
      transaction = Transaction.find(:all, :conditions => ["description = ? AND amount = ? AND transaction_date = ?", @transaction.description,@transaction.amount,@transaction.transaction_date], :select => 'id')
      if transaction.empty?
        if @transaction.amount > 0

          @transaction.payed = true

        end
        if @transaction.save
          n += 1
        else
     
          m += 1
        end
      else
        m += 1
      end
      message = "#{n} transaction succesfully recorded, #{m} transaction failed or already exist"
    end
    redirect_to(transactions_path)
    flash[:notice]=message
    
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

  #def auto_complete_for_transaction_description

   # @transactions = Transaction.find(:all,:select => 'DISTINCT description', :conditions => ['LOWER(description) LIKE ?', '%' + params[:transaction][:description].downcase + '%'])

    #render :partial => 'transactions'
  #end
 
end
