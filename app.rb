# encoding: UTF-8
require 'SecureRandom'
require 'json'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'tilt/erb'

Valutas = {
    :AUD => 1.3824,
    :BGN => 1.9558,
    :BRL => 3.2639,
    :CAD => 1.3386,
    :CHF => 1.039,
    :CNY => 6.5626,
    :CZK => 27.383,
    :EUR => 1.0,
    :DKK => 7.4716,
    :GBP => 0.7244,
    :HKD => 8.1919,
    :HRK => 7.574,
    :HUF => 297.38,
    :IDR => 13665.33,
    :ILS => 4.213,
    :INR => 65.91,
    :JPY => 127.32,
    :KRW => 1157.92,
    :MXN => 16.049,
    :MYR => 3.876,
    :NOK => 8.613,
    :NZD => 1.4059,
    :PHP => 47.147,
    :PLN => 4.0181,
    :RON => 4.409,
    :RUB => 54.537,
    :SEK => 9.3331,
    :SGD => 1.4439,
    :THB => 34.415,
    :TRY => 2.7921,
    :USD => 1.057,
    :ZAR => 12.746
}


class Bookkeeper < ActiveRecord::Base
    validates :Vārds, presence: true, uniqueness: true, length: { in: 1..100 }
    validates :Epasts, presence: true, uniqueness: true, length: { in: 3..255 }, format: { with: /\A[^@ ]+@[^@ ]+\z/ }
    validates :Parole, length: { in: 3..100 }
end

class Currency < ActiveRecord::Base
    has_one :amount
    validates :Apzīmējums, uniqueness: true, presence: true, length: { in: 1..10 }
    validates :Nosaukums, presence: true, length: { in: 1..50 }
end

class Amount < ActiveRecord::Base
    belongs_to :currency
    validates :Apjoms, :numericality => { :greater_than_or_equal_to => 0 }
end

class App < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    enable :sessions
    @page = nil
    @admin = false
    @username = nil

    helpers do
        def h(text)
            Rack::Utils.escape_html(text)
        end

        def is_int(str)
            Integer(str) rescue false
        end

        def kurss(no, uz)
            if no == :EUR
                Valutas[uz] || 1
            else
                (Valutas[uz] || 1) / kurss(:EUR, no)
            end
        end

        def generate_password(length)
            bytes = SecureRandom.random_bytes(length)
            password = ''
            charset = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
            bytes.each_byte do |byte|
                password = password + charset[byte % charset.length]
            end
            password
        end
    end

    not_found do
        erb :Neatrada
    end

    get '/' do
        if session['login']
            @username = session['login']
            @page = 'Apjomi'
            redirect to('/Apjomi')
        else
            erb :Login, :locals => { :iserror => 0 }
        end
    end

    post '/' do
        iserror = 1
        if params['username']
            bookkeeper = Bookkeeper.where('lower(Vārds) = ?', params['username'].downcase).take
            if bookkeeper and bookkeeper.Parole == params['password']
                unless bookkeeper.Bloķēts
                    session['login'] = bookkeeper.id
                    @username = bookkeeper.Vārds
                    @page = 'Apjomi'
                    iserror = 3
                    redirect to('/Apjomi')
                end
                iserror = 2
            end
        end
        @username = nil
        session['login'] = nil
        erb :Login, :locals => { :iserror => iserror }
    end

    get '/Admin' do
        if session['admin'] == true
            redirect to(URI.encode('/Admin/Valūtas'))
        else
            erb :Admin, :locals => { :iserror => false }
        end
    end

    post '/Admin' do
        if params['password'] and params['password'] == 'admin123'
            session['admin'] = true
            redirect to(URI.encode('/Admin/Valūtas'))
        else
            session['admin'] = false
            @admin = false
            erb :Admin, :locals => { :iserror => true }
        end
    end

    get '/Iziet' do
        @username = nil
        @admin = false
        session['login'] = nil
        session['admin'] = false
        redirect to('/')
    end

    get '/Apjomi' do
        redirect to('/') unless session['login']
        @page = 'Apjomi'
        @username = session['login']
        iserror = 0
        erb :Apjomi, :locals => { :currencies => Currency.all, :iserror => iserror }
    end

    post '/Apjomi' do
        redirect to('/') unless session['login']
        @page = 'Apjomi'
        @username = session['login']
        iserror = 1
        if params['change'] and params['fromcurrency'] and params['tocurrency'] and is_int(params['amount']) and params['amount'].to_i > 0
            valuta1 = Currency.where('Apzīmējums = ?', params['fromcurrency']).take
            valuta2 = Currency.where('Apzīmējums = ?', params['tocurrency']).take
            if valuta1 and valuta2 and params['fromcurrency'] != params['tocurrency'] and valuta1.amount.Apjoms >= params['amount'].to_i
                valuta1.amount.Apjoms -= params['amount'].to_i
                valuta2.amount.Apjoms += kurss(params['fromcurrency'].to_sym, params['tocurrency'].to_sym) * params['amount'].to_i
                if valuta1.amount.save and valuta2.amount.save
                    iserror = 2
                end
            end
        end
        erb :Apjomi, :locals => { :currencies => Currency.all, :iserror => iserror }
    end

    get '/Kurss' do
        redirect to('/') unless session['login']
        @page = 'Kurss'
        @username = session['login']
        erb :Kurss, :locals => { :rates => Valutas, :currencies => Currency.all.collect { |c| c.Apzīmējums } }
    end

    get '/Parole' do
        redirect to('/') unless session['login']
        @page = 'Parole'
        @username = session['login']
        erb :Parole, :locals => { :iserror => 0 }
    end

    post '/Parole' do
        redirect to('/') unless session['login']
        @page = 'Parole'
        @username = session['login']
        iserror = 1
        if params['password'] and params['newpassword']
            bookkeeper = Bookkeeper.find_by_id(session['login'])
            if bookkeeper and bookkeeper.Parole == params['password']
                bookkeeper.Parole = params['newpassword']
                iserror = 2 if bookkeeper.save
            end
        end
        erb :Parole, :locals => { :iserror => iserror }
    end

    get '/Admin/Valūtas' do
        redirect to('/') unless session['admin']
        @page = 'Valūtas'
        @admin = session['admin']
        iserror = session['iserror']
        session['iserror'] = 0
        erb :Valūtas, :locals => { :currencies => Currency.all, :iserror => iserror }
    end

    post '/Admin/Valūtas' do
        redirect to('/') unless session['admin']
        @page = 'Valūtas'
        @admin = session['admin']
        iserror = 1
        if params['add'] and params['identifier'] and params['name'] and params['amount'] and is_int(params['amount']) and params['amount'].to_i >= 0
            valuta = Currency.new
            valuta.Apzīmējums = params['identifier']
            valuta.Nosaukums = params['name']
            valuta.amount = Amount.new
            valuta.amount.Apjoms = params['amount'].to_i
            iserror = 2 if valuta.save and valuta.amount.save
        elsif params['save'] and params['id'] and params['id'].to_i > 0 and params['amount'] and is_int(params['amount']) and params['amount'].to_i >= 0
            valuta = Currency.find_by_id(params['id'].to_i)
            valuta.amount.Apjoms = params['amount'].to_i
            iserror = 2 if valuta.amount.save
        end
        erb :Valūtas, :locals => { :currencies => Currency.all, :iserror => iserror }
    end

    get '/Admin/Valūtas/Dzēst/:id' do |id|
        redirect to('/') unless session['admin']
        @page = 'Valūtas'
        @admin = session['admin']
        iserror = 1
        valuta = Currency.find_by_id(id.to_i)
        iserror = 2 if valuta and valuta.amount.destroy and valuta.destroy
        session['iserror'] = iserror
        redirect to(URI.encode('/Admin/Valūtas'))
    end

    get '/Admin/Grāmatveži' do
        redirect to('/') unless session['admin']
        @page = 'Grāmatveži'
        @admin = session['admin']
        iserror = session['iserror']
        session['iserror'] = 0
        erb :Grāmatveži, :locals => { :bookkeepers => Bookkeeper.all, :iserror => iserror }
    end

    get '/Admin/Grāmatveži/Dzēst/:id' do |id|
        redirect to('/') unless session['admin']
        @page = 'Grāmatveži'
        @admin = session['admin']
        iserror = 1
        bookkeeper = Bookkeeper.find_by_id(id)
        iserror = 2 if bookkeeper and bookkeeper.destroy
        session['iserror'] = iserror
        redirect to(URI.encode('/Admin/Grāmatveži'))
    end

    post '/Admin/Grāmatveži' do
        redirect to('/') unless session['admin']
        @page = 'Grāmatveži'
        @admin = session['admin']
        iserror = 1
        if params['add'] and params['username'] and params['email']
            gramatvedis = Bookkeeper.new
            gramatvedis.Vārds = params['username']
            gramatvedis.Epasts = params['email']
            gramatvedis.Parole = generate_password(10)
            if gramatvedis.save
                iserror = 2
                File.write('emails/' + gramatvedis.Epasts.gsub(/[@\\\/]/, '_') + '.txt', "Jūs tikāt reģistrēts Valūtas uzskaites sistēma ar vārdu #{gramatvedis.Vārds} un paroli #{gramatvedis.Parole}")
            end
        else params['save'] and params['id'] and params['id'].to_i > 0 and params['email']
            gramatvedis = Bookkeeper.find_by_id(params['id'].to_i)
            gramatvedis.Epasts = params['email']
            gramatvedis.Bloķēts = params['blocked'] ? true : false
            iserror = 2 if gramatvedis.save
        end
        erb :Grāmatveži, :locals => { :bookkeepers => Bookkeeper.all, :iserror => iserror }
    end

end
