FROM ruby:3.3-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    whois \
    dnsutils \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT ["ruby", "generate_data.rb"]