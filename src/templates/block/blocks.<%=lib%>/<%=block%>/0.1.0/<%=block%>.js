jBlock

.match('<%= block %>', function()
{
    this.append(
        {b_snippet: this.copy()}
    );
})
