class TLDR
  class SorbetCompatibility
    def self.unwrap_method method
      return method unless defined? ::T::Private::Methods

      sig_or_method = ::T::Private::Methods.signature_for_method(method) || method

      if sig_or_method.is_a?(Method) || sig_or_method.is_a?(UnboundMethod)
        sig_or_method
      else # it's a T::Private::Methods::Signature
        sig_or_method.method
      end
    end
  end
end
