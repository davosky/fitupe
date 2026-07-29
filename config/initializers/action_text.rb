# Trix's default sanitizer allowlist has no <u> tag, so the custom "underline"
# text attribute registered in app/javascript/controllers/trix_controller.js
# would otherwise be stripped when the rich text is saved or rendered.
Rails.application.config.to_prepare do
  ActionText::ContentHelper.allowed_tags = ActionText::ContentHelper.sanitizer.class.allowed_tags +
    [ ActionText::Attachment.tag_name, "figure", "figcaption", "u" ]
end
