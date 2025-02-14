# refactored_interaction

# Оглавление

- [Описание](#описание)
- [Задачи](#задачи)
- [Рефакторинг класса Users::Create](#рефакторинг-класса-userscreateuser)
- [Исправление опечатки в модели Skill](#исправление-опечатки-в-модели-skill)
- [Исправление связей между моделями](#исправление-связей-между-моделями)
- [Написание тестов](#написание-тестов)
- [Установка](#установка)
- [API Endpoints](#api-endpoints)
- [POST /users](#post-users)
- [POST /interests](#post-interests)
- [POST /skills](#post-skills)

## Описание

Данный проект демонстрирует рефакторинг кода,
в рамках которого была реализована логика создания
пользователей в приложении на Ruby on Rails.
В работе был использован gem [ActiveInteraction](https://github.com/AaronLasseigne/active_interaction) для организации
бизнес-логики,
а также произведены исправления в моделях и связях с помощью
гема [OnlineMigrations](https://github.com/fatkodima/online_migrations).
Ниже описаны задачи, выполненные в ходе выполнения задания.

## Задачи

Были выполнены следующие шаги:

#### Произведен рефакторинг класса Users::CreateUser

❌ До рефакторинга:

```ruby
# app/interactions/users/create_user.rb
class Users::Create < ActiveInteraction::Base
  hash :params

  def execute
    #don't do anything if params is empty
    return unless params['name']
    return unless params['patronymic']
    return unless params['email']
    return unless params['age']
    return unless params['nationality']
    return unless params['country']
    return unless params['gender']
    ##########
    return if User.where(email: params['email'])
    return if params['age'] <= 0 || params['age'] > 90
    return if params['gender'] != 'male' or params['gender'] != female
    user_full_name = "#{params['surname']} #{params['name']} #{params['patronymic']}"
    user_params = params.except(:interests)
    user = User.create(user_params.merge(user_full_name))
    Intereset.where(name: params['interests']).each do |interest|
      user.interests = user.interest + interest
      user.save!
    end
    user_skills = []
    params['skills'].split(',').each do |skil|
      skil = Skil.find(name: skil)
      user_skills = user_skills + [skil]
    end
    user.skills = user_skills
    user.save
  end
end
```

✅После рефакторинга:

* Определены входные данные

```ruby
string :name, :patronymic, :surname, :nationality, :country, :gender, :email
integer :age
array :skills_attributes, :interests_attributes do
  hash do
    string :name
  end
end
```

* Настроены необходимые валидации

```ruby
set_callback :filter, :before, -> {
  self.gender = gender.downcase if gender.present?
}

validates :name, :patronymic, :surname, :email, :age, :nationality, :country,
          :gender, presence: true

validates :email,
          format: { with: URI::MailTo::EMAIL_REGEXP,
                    message: "%{value} is not a valid email" }

validates :age,
          numericality: { greater_than: 0, less_than_or_equal_to: 90,
                          message: "%{value} is not a valid age" }
validates :gender,
          inclusion: { in: %w[male female],
                       message: "%{value} is not a valid gender" }
```

* Реализована логика создания пользователя

```ruby
def execute
  user = User.new(inputs.except(:skills_attributes, :interests_attributes).merge(gender: gender))


  skills = skills_attributes.map { |item| Skill.find_or_initialize_by(name: item[:name]) }
  interests = interests_attributes.map { |item| Interest.find_or_initialize_by(name: item[:name]) }

  start_transaction(user, skills, interests)
  user
end

private

def start_transaction(user, skills, interests)
  ActiveRecord::Base.transaction do
    user.save!
    skills.each(&:save!)
    interests.each(&:save!)
    user.skills.concat(skills)
    user.interests.concat(interests)
    raise ActiveRecord::Rollback if [user, *skills, *interests].any?(&:invalid?)
  end
end
```

#### Исправлена опечатка в моделе Skill

❌ Простое переименование таблицы на продакшене является опасным,
грозит возникновением ошибок и падением сервера:

```ruby

class RenameSkilToSkill < ActiveRecord::Migration[8.0]
  def change
    rename_table :skils, :skills
  end
end
```

Можно выполнить следющие 6 шагов, чтобы недопустить подобных проблем:

1. Создать новую таблицу
2. Записывать данные одновременно в обе таблицы
3. Перенести данные из старой таблицы в новую
4. Переключить чтение данных со старой таблицы на новую
5. Прекратить запись в старую таблицу
6. Удалить старую таблицу

Несмотря на то, что такой подход является безопасным,
он может быть довольно ресурсоёмким для очень больших таблиц.

✅ С помощью OnlineMigrations удалось сделать этот процесс более эффективным:

1. Подготавливаем Rails к переименованию таблицы

```ruby
OnlineMigrations.config.table_renames = {
  "skils" => "skills"
}
```

2. Деплой
3. Создаем VIEW

```ruby

class InitializeRenameSkilsToSkills < ActiveRecord::Migration[8.0]
  def change
    initialize_table_rename :skils, :skills
  end
end
```

4. Заменяем использование старой таблицы (skils) на новую (skills)
5. Удаляем конфигурация из шага 1
6. Деплой
7. Удаляем VIEW, созданный на шаге 3

```ruby

class FinalizeRenameSkilsToSkills < ActiveRecord::Migration[8.0]
  def change
    finalize_table_rename :skils, :skills
  end
end
```

8. Деплой

#### Исправлены связи между моделями

* Обнаружено, что в моделях используется отношение многие-ко-многим.
* Настроены ассоциации has_many :through
* Созданы промежуточные модели

Поскольку добавление нескольких внешних ключей в одной миграции
блокирует запись во все затронутые таблицы до завершения миграции,
было решено добавлять внешние ключи посредством отдельных миграций:

```ruby

class CreateUserSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :user_skills do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :skill, foreign_key: false
      t.timestamps
    end
  end
end

class AddForeignKeyFromUserSkillsToSkill < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :user_skills, :skills, validate: false
  end
end
```

Также в отдельную миграцию была вынесена валидация существующих строк,
чтобы избежать блокировки таблицы:

```ruby

class ValidateForeignKeyOnUserSkills < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :user_skills, :skills
  end
end
```

#### Написаны тесты

Проект был покрыт тестами, а именно:

* Контроллеры: UsersController, InterestsController, SkillsController
* Класс Users::CreateUser

## Установка

Клонируйте репозиторий:

```
git clone <url>
cd <название_папки>
```

Установите зависимости:

```
bundle install
```

Установите PostgreSQL:

```
brew install postgresql # MacOS
sudo apt install postgresql postgresql-contrib libpq-dev # Linux
```

Запустите PostgreSQL:

```
brew services start postgresql # MacOS
sudo systemctl start postgresql # Linux
```

Поднимите базу данных:

```
rails db:create 
rails db:migrate
```

Запустите сервер:

```
rails server
```

Примените тесты:

```
bundle exec rspec
```

## API Endpoints

Access the API at http://localhost:3000

#### POST /users

Создание нового пользователя.

##### Request

Headers: Content-Type: application/json

Example Body:

```
{
"user": {
  "name": "John",
  "patronymic": "Doe",
  "surname": "Smith",
  "email": "john.doe@example.com",
  "age": 30,
  "nationality": "American",
  "country": "USA",
  "gender": "male",
  "interests_attributes": [{ "name": "Reading" }, { "name": "Traveling" }],
  "skills_attributes": [{ "name": "Ruby" }, { "name": "JavaScript" }]
}
}
```

##### Response

Success (201):

```
{"id":1,"name":"John","patronymic":"Doe","surname":"Smith","email":"john.doe@example.com","age":30,"nationality":"American","country":"USA","gender":"male","created_at":"2025-02-14T08:47:31.901Z","updated_at":"2025-02-14T08:47:31.901Z"}
```

Example Error (422):

```
{
    "email": [
        "invalid_email is not a valid email"
    ]
}
```

#### POST /interests

Создание нового интереса.

##### Request

Headers: Content-Type: application/json

Example Body:

```
{
  "interest": {
    "name": "Reading"
  }
}
```

##### Response

Success (201):

```
{"id":1,"name":"Reading","created_at":"2025-02-14T08:51:59.377Z","updated_at":"2025-02-14T08:51:59.377Z"}
```

Example Error (422):

```
{"name":["can't be blank"]}
```

#### POST /skills

Создание нового навыка.

##### Request

Headers: Content-Type: application/json

Example Body:

```
{
  "skill": {
    "name": "Ruby"
  }
}
```

##### Response

Success (201):

```
{"id":1,"name":"Ruby","created_at":"2025-02-14T08:53:05.978Z","updated_at":"2025-02-14T08:53:05.978Z"}
```

Example Error (422):

```
{"name":["can't be blank"]}
```
