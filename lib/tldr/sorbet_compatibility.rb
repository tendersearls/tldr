class TLDR
  class SorbetCompatibility
    def self.unwrap_method method
      return method unless defined? ::T::Private::Methods

      T::Private::Methods.signature_for_method(method).method || method
    end
  end
end
