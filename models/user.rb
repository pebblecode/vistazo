class User
  include MongoMapper::Document

  key :name, String
  key :uid, String
  key :email, String, :required => true

  timestamps!

  # Relationships
  belongs_to :account

  # Validations
  validates_format_of :email, :with => /\b[a-zA-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
  validates_presence_of :account_id

  def is_pending?
    self.status == :pending
  end
  
  def is_active?
    self.status == :active
  end
  
  def status
    if self.valid? 
      if (self.uid == nil) and (self.email != nil)     # Missing email
        :pending
      elsif (self.uid != nil) and (self.email != nil)  # Email and uid present
        :active
      else
        :unknown
      end
    else
      :invalid
    end
  end
end
