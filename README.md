# infrastructure

This repo holds the configuration for RPCh infrastructure such as:

- Terraform manifests
- Ansible roles

## Loki

Loki is a powerful tool for log analysis and searching, and it supports regular expressions (regex) for more advanced log queries. Here are some techniques and tips for using regex with Loki effectively:

1. **Basics of Regex in Loki:**
   - Loki uses the [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions.
   - Regular expressions are enclosed in forward slashes `/regex_pattern/`.

2. **Anchors:**
   - Use `^` to match the start of a line and `$` to match the end of a line. For example, `/^error$/` will match lines containing only the word "error."

3. **Character Classes:**
   - `[abc]` matches any single character 'a', 'b', or 'c'.
   - `[a-z]` matches any single lowercase letter.
   - `[A-Z]` matches any single uppercase letter.
   - `[0-9]` matches any single digit.

4. **Quantifiers:**
   - `*` matches zero or more of the preceding character or group.
   - `+` matches one or more of the preceding character or group.
   - `?` matches zero or one of the preceding character or group.
   - `{n}` matches exactly 'n' occurrences.
   - `{n,}` matches 'n' or more occurrences.
   - `{n,m}` matches between 'n' and 'm' occurrences.

5. **Escape Special Characters:**
   - Use `\` to escape special characters like `.`, `*`, `+`, `?`, etc. For example, `/\.error\*/` matches ".error*" literally.

6. **Grouping and Alternation:**
   - Use `()` for grouping and `|` for alternation. For example, `/(error|warning)/` matches either "error" or "warning."

7. **Word Boundaries:**
   - `\b` matches word boundaries. For example, `/error\b/` matches "error" as a whole word but not "errors."

8. **Character Sets and Negation:**
   - `[abc]` matches any single character 'a', 'b', or 'c'.
   - `[^abc]` matches any character except 'a', 'b', or 'c'.

9. **Case-Insensitive Matching:**
   - Add `(?i)` at the beginning of the regex to make it case-insensitive. For example, `/(?i)error/` matches "error," "ERROR," "Error," etc.

10. **Capture Groups:**
    - Use `()` to create capture groups, which can be used to extract specific parts of the log entry. For example, `/(error) (\d+)/` captures "error" and the following digits as separate groups.

11. **Lookarounds:**
    - Lookaheads `(?=pattern)` and negative lookaheads `(?!=pattern)` allow you to assert that a certain pattern exists (or doesn't exist) ahead in the text without consuming characters.

12. **Testing and Debugging:**
    - Use online regex testers like [regex101](https://regex101.com/) or [RegExr](https://regexr.com/) to test and debug your regular expressions before using them in Loki queries.

13. **Optimization:**
    - Be cautious with complex regex patterns as they can be computationally expensive. Try to make your patterns as specific as necessary to avoid performance issues.

Remember that regex can become quite complex for intricate log parsing tasks, so it's essential to balance accuracy with performance when using Loki for log analysis. Regular expressions are a powerful tool, but they can also be a source of performance bottlenecks if not used carefully.

## Notes

- To get the outputs from Terraform with the IPv4 addresses, you can use the following command:

```shell
terraform output -json main | jq -r '.[]' | sort -n
```

- To run the Ansible playbook, use the following command:

```shell
ansible-playbook -i hosts install.yaml
```
