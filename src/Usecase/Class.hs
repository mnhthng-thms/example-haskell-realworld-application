module Usecase.Class where

import           ClassyPrelude
import qualified Data.Validation               as Validation
import qualified Domain.User                   as Domain

data Interactor m = Interactor {
  userRepo_ :: UserRepo m,
  checkEmailFormat_ :: Monad m => CheckEmailFormat m,
  genUUID_ :: Monad m => GenUUID m
}

data UserRepo m = UserRepo {
  getUserByID_ :: Monad m => GetUserByID m,
  getUserByEmail_ :: Monad m => GetUserByEmail m,
  getUserByName_ :: Monad m => GetUserByName m,
  getUserByEmailAndHashedPassword_ :: Monad m => GetUserByEmailAndHashedPassword m
}

--UserRepo functions
type GetUserByID m = Monad m => Text -> m (Maybe Domain.User)
type GetUserByEmail m = Monad m => Text -> m (Maybe Domain.User)
type GetUserByName m = Monad m => Text -> m (Maybe Domain.User)
type GetUserByEmailAndHashedPassword m
        = Monad m => Text -> Text -> m (Maybe Domain.User)

-- Mail utilies
type CheckEmailFormat m
        = Monad m => Text -> m (Validation.Validation [Domain.Error] ())

type GenUUID m = Monad m => m Text

class Monad m =>
      Logger m
    where
    log :: Show a => [a] -> m ()


class Monad m =>
      Hasher m
  where
  hashText :: Text -> m Text

