module UCSpecs.UserRegistrationSpec
  ( spec
  )
where

import           RIO

import           Test.Hspec

import           Lib
import           Utils

import qualified Adapter.EmailChecker          as MailChecker
import qualified Adapter.Fake.Logger           as Logger
import qualified Adapter.Fake.UUID             as Uuid

import qualified Adapter.Storage.InMem.User    as InMem
import qualified Domain.User                   as D
import qualified Usecase.Interactor            as UC
import qualified Usecase.UserRegistration      as UC

uc :: UC.Register App
uc = UC.register (UC._genUUID i)
                 (UC._checkEmailFormat i)
                 (UC._getUserByEmail $ UC._userRepo i)
                 (UC._getUserByName $ UC._userRepo i)
 where
  i = UC.Interactor (UC.UserRepo undefined undefined InMem.getUserByEmail InMem.getUserByName undefined)
                    MailChecker.checkEmailFormat
                    (Uuid.genUUID defaultFakeUUID)
                    undefined

registerUser :: State -> UC.Register IO
registerUser state name email password = run state $ uc name email password

spec :: Spec
spec = do
  let prevUser       = D.User "prevID" "collidingUserName" "colliding@email.fr"
      currUser       = D.User "currID" "currentUserName" "current@email.fr"
      malformedEmail = "current.email.fr" :: Text
      password       = "myPass" :: Text

  describe "happy case" $ it "should return the uuid" $ do
    state      <- emptyState
    Right uuid <- registerUser state (D._name currUser) (D._email currUser) password
    uuid `shouldBe` defaultFakeUUID


  describe "collision with other user email" $ it "raises an UserEmailAlreadyInUse error" $ do
    state <- emptyState
    run state $ InMem.insertUser (D._id prevUser) (D._name prevUser) (D._email prevUser) password
    Left resp <- registerUser state (D._name currUser) (D._email prevUser) password
    resp `shouldBe` [D.ErrUserEmailAlreadyInUse]
    checkLogs state [D.ErrUserEmailAlreadyInUse]


  describe "collision with other user name" $ it "raises an UserNameAlreadyInUse error" $ do
    state <- emptyState
    run state $ InMem.insertUser (D._id prevUser) (D._name prevUser) (D._email prevUser) password
    Left resp <- registerUser state (D._name prevUser) (D._email currUser) password
    resp `shouldBe` [D.ErrUserNameAlreadyInUse]
    checkLogs state [D.ErrUserNameAlreadyInUse]


  describe "collision with other user name & other user email"
    $ it "raises UserNameAlreadyInUse & UserEmailAlreadyInUse errors"
    $ do
        state <- emptyState
        run state $ InMem.insertUser (D._id prevUser) (D._name prevUser) (D._email prevUser) password
        Left resp <- registerUser state (D._name prevUser) (D._email prevUser) password
        resp `shouldMatchList` [D.ErrUserNameAlreadyInUse, D.ErrUserEmailAlreadyInUse]
        checkLogs state [D.ErrUserNameAlreadyInUse, D.ErrUserEmailAlreadyInUse]


  describe "malformed email" $ it "raises an MalformedEmail error" $ do
    state     <- emptyState
    Left resp <- registerUser state (D._name currUser) malformedEmail password
    resp `shouldMatchList` [D.ErrMalformedEmail]
    checkLogs state [D.ErrMalformedEmail]
