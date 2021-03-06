module Adapter.Storage.InMem.User where

import           RIO
import qualified RIO.Map                       as Map
import qualified Data.Has                      as DH
import qualified Data.UUID                     as UUID

import qualified Domain.User                   as D
import qualified Usecase.Interactor            as UC

type InMemory r m = (DH.Has (TVar Store) r, MonadReader r m, MonadIO m)


type Name = Text


data User = User {
  _id :: !UUID.UUID
  , _name :: !Text
  , _email :: !Text
  , _password :: !Text
  } deriving ( Show, Eq )


newtype Store = Store {
  users :: Map UUID.UUID User
  }


fromDomain :: D.User -> User
fromDomain d = User (D._id d) (D._name d) (D._email d) ""


toDomain :: User -> D.User
toDomain u = D.User (_id u) (_name u) (_email u)


insertUserPswd :: InMemory r m => UC.InsertUserPswd m
insertUserPswd (D.User uid' name' email') password' = do
  tvar <- asks DH.getter
  atomically $ do
    state <- readTVar tvar
    writeTVar tvar
              state { users = Map.insert uid' (User uid' name' email' password') $ users state }
    pure $ Nothing


getUserByID :: InMemory r m => UC.GetUserByID m
getUserByID userID = do
  tvar <- asks DH.getter
  atomically $ do
    state <- readTVar tvar
    pure $ Right $ toDomain <$> Map.lookup userID (users state)


getUserByEmail :: InMemory r m => UC.GetUserByEmail m
getUserByEmail email' = commonSearch (\u -> email' == _email u)


getUserByName :: InMemory r m => UC.GetUserByName m
getUserByName name' = commonSearch (\u -> name' == _name u)


getUserByEmailAndHashedPassword :: InMemory r m => UC.GetUserByEmailAndHashedPassword m
getUserByEmailAndHashedPassword email' pass' =
  commonSearch (\u -> email' == _email u && pass' == _password u)


commonSearch :: InMemory r m => (User -> Bool) -> m (Either (UC.Err Void) (Maybe D.User))
commonSearch filter_ = do
  tvar <- asks DH.getter
  atomically $ do
    state <- readTVar tvar
    case filter filter_ $ map snd $ Map.toList (users state) of
      []      -> pure $ Right Nothing
      (x : _) -> pure $ Right (Just (toDomain x))

