FROM ruby:2.6.2-alpine

WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN gem install bundler
RUN bundle install --system

ADD server.rb /app
RUN bundle install --system

EXPOSE 4567

CMD ["ruby", "server.rb"]
