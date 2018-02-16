namespace :crawler do
  desc "Manually trigger the crawler"
  task crawl: :environment do

    puts "Running crawler in background"

    PublisherCrawler.perform_async( 'vice.com' )
  end

end
