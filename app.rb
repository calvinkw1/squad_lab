require 'sinatra'
require 'pry'
require 'pg'
require 'better_errors'
# use shotgun or rerun instead of sinatra reloader
configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

set :conn, PG.connect(dbname: 'squad_lab')

before do
  @conn = settings.conn
end

# ROOT
get '/' do
 redirect '/squads'
end 

# GET ALL SQUADS
get '/squads' do
  squads = []
  @conn.exec("SELECT * FROM squads") do |result|
    result.each do |squad|
      squads << squad
    end
  end
  @squads = squads
  erb :index
end

# NEW SQUAD
get '/squads/new' do
  erb :new
end

# NEW STUDENT
get '/squads/:squad_id/students/new' do |squad|
  squad = @conn.exec("SELECT * FROM squads WHERE id = $1", [params[:squad_id]])
  @squad = squad[0]
  erb :new_student
end

# SHOW SQUAD INFO
get '/squads/:squad_id' do
  squad_id = params[:squad_id].to_i
  @conn.exec("SELECT * FROM squads WHERE id = $1", [squad_id]) do |id|
    @squad_id = id[0]
  end
  erb :show
end

# SHOW SQUAD STUDENTS
get '/squads/:squad_id/students' do
  id = params[:squad_id].to_i
  @squad_id = id
  squad_students = []
  @conn.exec("SELECT * FROM students WHERE squad_id = $1", [id]) do |result|
    result.each do |students|
      squad_students << students
    end
  end
  @squad_students = squad_students
  erb :students
end

# SHOW STUDENT INFO
get '/squads/:squad_id/students/:student_id' do
  squad_id = params[:squad_id].to_i
  @squad_id = squad_id
  student_id = params[:student_id].to_i
  @student_id = student_id
  @conn.exec("SELECT * FROM students WHERE squad_id = $1 and id = $2", [squad_id, student_id]) do |student|
    @student = student[0]
    # binding.pry
  end
  erb :show_student
end

# EDIT SQUAD
get '/squads/:squad_id/edit' do
  squad_id = params[:squad_id].to_i
  @conn.exec("SELECT * FROM squads WHERE id = $1", [squad_id]) do |id|
    @squad_id = id[0]
  end
  erb :edit
end

# EDIT STUDENT
get '/squads/:squad_id/students/:student_id/edit' do
  squad_id = params[:squad_id].to_i
  @squad_id = squad_id
  student_id = params[:student_id].to_i
  @student_id = student_id
  @conn.exec("SELECT * FROM students WHERE squad_id = $1 and id = $2", [squad_id, student_id]) do |student|
    @student = student[0]
    # binding.pry
  end
  erb :edit_student
end

# CREATE SQUAD
post '/squads' do
  @conn.exec("INSERT INTO squads (squad_name, mascot) VALUES ($1, $2)", [params[:squad_name], params[:mascot]])
  redirect '/squads'
end

# CREATE STUDENT
post '/squads/:squad_id/students' do
  squad_id = params[:squad_id].to_i
  student_name = params[:student_name]
  age = params[:age].to_i
  spirit_animal = params[:spirit_animal]
  @conn.exec("INSERT INTO students (squad_id, student_name, age, spirit_animal) VALUES ($1, $2, $3, $4)", [squad_id, student_name, age, spirit_animal])
  redirect '/squads/' << params[:squad_id] << '/students'
end

# UPDATE SQUAD
put '/squads/:squad_id' do
  id = params[:squad_id].to_i
  squad_name = params[:squad_name]
  mascot = params[:mascot]
  @conn.exec("UPDATE squads SET squad_name = $1, mascot = $2 WHERE id = $3", [squad_name, mascot, id])
  redirect '/squads'
end

# UPDATE STUDENT
put '/squads/:squad_id/students/:student_id' do
  id = params[:student_id].to_i
  student_name = params[:student_name]
  age = params[:age]
  spirit_animal = params[:spirit_animal]
  @conn.exec("UPDATE students SET student_name = $1, age = $2, spirit_animal = $3 WHERE id = $4", [student_name, age, spirit_animal, id])
  redirect '/squads/' << params[:squad_id] << '/students'
end


# DELETE SQUAD
delete '/squads/:squad_id' do
  squad_id = params[:squad_id]
  counter = 0
  @conn.exec("SELECT COUNT(*) FROM students WHERE squad_id = $1", [squad_id]) do |x|
    counter = x
  end
  if counter > 0
    erb :nodelete
  else
    @conn.exec("DELETE FROM squads WHERE id = $1", [squad_id])
    redirect '/squads'
  end
end

# DELETE STUDENT
delete '/squads/:squad_id/students/:student_id' do
  id = params[:student_id]
  squad_id = params[:squad_id]
  @conn.exec("DELETE FROM students WHERE id = $1 AND squad_id = $2", [id, squad_id])
  redirect '/squads/' << squad_id << '/students'
end