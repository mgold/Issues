class Issue

  # Symbols
  attr_reader :owner, :repo, :state
  #Strings
  attr_reader :title, :opened_by
  #Integers
  attr_reader :number, :comment_count
  #Times
  attr_reader :opened_at, :closed_at

  def initialize(owner, repo, sawyer_obj)
    @owner = owner.to_sym
    @repo = repo.to_sym
    @number = sawyer_obj.number
    @title = sawyer_obj.title
    @opened_at = sawyer_obj.created_at
    @closed_at = sawyer_obj.closed_at
    @opened_by = sawyer_obj.user.login
    @state = sawyer_obj.state.to_sym
    @is_pr = sawyer_obj.attrs.has_key? :pull_request
    @comment_count = sawyer_obj.comments
  end

  def pr?
    @is_pr
  end

  def open?
    @closed_at.nil?
  end

  def closed?
    !open?
  end

  def closed_during?(start, finish=nil)
    closed? && start < closed_at && (finish.nil? || finish > closed_at)
  end

  def opened_during?(start, finish=nil)
    start < opened_at && (finish.nil? || finish > opened_at)
  end

  def duration
    return unless closed_at
    closed_at - opened_at
  end

  def url
    "https://github.com/#{owner}/#{repo}/#{pr? ? "pull" : "issues"}/#{number}"
  end
end
