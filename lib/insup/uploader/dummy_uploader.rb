require 'colorize'

class Insup
  class Uploader
    class DummyUploader < Insup::Uploader
      register_uploader :dummy

      def upload_file(file)
        case file.state
        when Insup::TrackedFile::NEW
          changed
          notify_observers(CREATING_FILE, file)
          changed
          notify_observers(CREATED_FILE, file)
        when Insup::TrackedFile::MODIFIED, Insup::TrackedFile::UNSURE
          changed
          notify_observers(MODIFYING_FILE, file)
          changed
          notify_observers(MODIFIED_FILE, file)
        end
      end

      def remove_file(file)
        changed
        notify_observers(DELETING_FILE, file)
        changed
        notify_observers(DELETED_FILE, file)
      end

      def batch_upload(files)
        changed
        notify_observers(BATCH_UPLOADING_FILES, files)
        changed
        notify_observers(BATCH_UPLOADED_FILES, files)
      end
    end
  end
end
