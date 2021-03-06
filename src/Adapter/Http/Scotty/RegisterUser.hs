module Adapter.Http.Scotty.RegisterUser where

import           RIO
import           RIO.Text.Lazy
import           Network.HTTP.Types             ( status422, status500 )
import qualified Web.Scotty.Trans              as ScottyT

import           Adapter.Http.Lib              as Lib
import           Usecase.UserRegistration      as UC

registerUser :: MonadIO m => UC.Register m -> ScottyT.ActionT LText m ()
registerUser uc = do
  (Lib.User body) <- ScottyT.jsonData
  resp            <- lift
    $ uc (Lib.register_email body) (Lib.register_username body) (Lib.register_password body)
  case resp of
    Left  (UC.ErrValidation _) -> ScottyT.status status422
    Left  (UC.ErrTechnical   ) -> ScottyT.status status500
    Right uuid                 -> ScottyT.html $ fromStrict uuid
