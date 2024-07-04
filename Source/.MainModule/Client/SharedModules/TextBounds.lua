local TextService = game:GetService("TextService")
function TextBounds(Label)
	local TextBoundsParams = Instance.new('GetTextBoundsParams')
	TextBoundsParams.Width = Label.AbsoluteSize.X
	
	TextBoundsParams.Size = Label.TextSize
	TextBoundsParams.Font = Label.FontFace
	TextBoundsParams.Text = Label.Text

	TextBoundsParams:Destroy()
	local TextBounds = TextService:GetTextBoundsAsync(TextBoundsParams)
	return TextBounds
end

return TextBounds
