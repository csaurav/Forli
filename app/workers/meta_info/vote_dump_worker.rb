class MetaInfo::VoteDumpWorker

  include Sidekiq::Worker

  sidekiq_options :queue => :vote_dump_worker, :retry => 0, :backtrace => true

  def perform(options)
  end

end