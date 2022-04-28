class LineController < ApplicationController
  # callbackアクションのCSRFトークン認証を無効  
  protect_from_forgery :except => [:callback] 
  require 'line/bot'

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      header_only(:bad_request)
    end

    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          line_user_id = event['source']['userId']
          @user = User.find_or_create_by(line_user_id: line_user_id)

          byebug
          case @user.mode
          when 0 #待機モード
            case event.message['text']
            when 'わすれんぞう覚えて'
              reply = 'なにを覚えてほしいんじゃ？'
              @user.mode = 10
            when 'わすれんぞう思い出して'
              reply = 'なにを思い出してほしいんじゃ？'
              @user.mode = 20
            when 'わすれんぞう忘れて'
              reply = 'なにを忘れてほしいんじゃ？'
              @user.mode = 30
            when 'わすれんぞう話しかけて'
              question_topic = @user.topics.sample
              if question_topic.present?
                reply = "そういや、「#{question_topic.title}」はどういう意味じゃったかのう？"
                @user.mode = 40 + question_topic.id
              else
                reply = 'わしはまだなにも覚えとらんぞ'
              end
            else
              reply = '急に話しかけられても困るわい。わしが聞き取れるのは「わすれんぞう覚えて」「わすれんぞう思い出して」「わすれんぞう忘れて」「わすれんぞう話しかけて」の4つじゃ'
            end
          when 10, 11 #覚えるモード
            if @user.mode == 10
              topic = @user.topics.new(title: event.message['text'], content: 'not_enterd')
              if topic.save
                reply = "「#{topic.title}」じゃな。それはどういう意味なんじゃ？"
                @user.mode = 11
              else
                reply = 'エラーじゃ'
                @user.mode = 0
              end
            else
              topic = @user.topics.order(updated_at: :desc).find_by(content: 'not_enterd')
              topic.content = event.message['text']
              if topic.save
                reply = "「#{topic.content}」という意味じゃな。覚えたぞい"
              else
                reply = 'エラーじゃ'
              end
              @user.mode = 0
            end
          when 20 #思い出すモード
            topic = @user.topics.find_by(title: event.message['text'])
            if topic.present?
              reply = "それは「#{topic.content}」という意味じゃ"
            else
              reply = 'エラーじゃ'
            end
            @user.mode = 0
          when 30 #忘れるモード
            topic = @user.topics.find_by(title: event.message['text'])
            if topic.present?
              reply = "「#{topic.title}」を忘れるぞい。せっかく覚えたのに残念じゃ"
              topic.destroy
            else
              reply = 'エラーじゃ'
            end
            @user.mode = 0
          else #回答モード
            answer_topic = Topic.find(@user.mode - 40)
            if answer_topic.present?
              if event.message['text'] == answer_topic.content
                reply = "そうじゃったそうじゃった。「#{answer_topic.content}」という意味じゃったな。若者の記憶力にはかなわんぞい"
              else
                reply = "はて？　そんな意味じゃったかいのう？　いかん、「#{answer_topic.title}」のことはすっかり忘れてしまったわい…"
                answer_topic.destroy
              end
            else
              reply = 'エラーじゃ'
            end
            @user.mode = 0
          end
          message = {
            type: 'text',
            text: reply
          }
          client.reply_message(event['replyToken'], message)
          @user.save
        end
      end
    end
    head :ok
  end

  private

  # LINE Developers登録完了後に作成される環境変数の認証
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET_WASURENZOU']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN_WASURENZOU']
    }
  end

end
