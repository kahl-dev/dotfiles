## Hook Error Response Protocol

When PostToolUse hooks report errors (especially linting):

1. **Read the error output carefully** - hooks provide specific file:line locations
2. **Immediately fix all reported issues** using Edit tool:
   - Remove unused variables
   - Fix type mismatches
   - Correct formatting issues
3. **Retry the original operation** after fixing
4. **Never proceed** until all hook errors are resolved

Hook errors are blocking issues that must be fixed before continuing.