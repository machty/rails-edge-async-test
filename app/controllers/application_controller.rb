class ApplicationController < ActionController::Base
  def index
    @messages = []
    @start = Time.now
    @time = Benchmark.realtime do
      tasks = [
        3.times.map do |i|
          run_in_async_task("HTTParty #{i}") do
            HTTParty.get("https://httpstat.us/200?sleep=1000")
          end
        end,
        3.times.map do |i|
          run_in_async_task("Postgres pg_sleep(1) #{i}") do
            ActiveRecord::Base.connection.execute("select pg_sleep(1);")
          end
        end,
      ].flatten

      @results = tasks.map(&:wait)
    end
  end

  def run_in_async_task(tag)
    Async do
      log "#{tag} starting on Fiber #{Fiber.current.object_id}"
      value = yield
      log "#{tag} done in"
      [tag, value]
    end
  end

  def log(message)
    message = "#{(Time.now - @start).round(2)}s #{message}"
    puts "#{message}\n"
    @messages << message
  end
end
