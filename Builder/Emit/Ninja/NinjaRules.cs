namespace LumenBuilder
{

    namespace Emit
    {

        namespace Ninja
        {

            /// <summary>
            /// Ninja build rules definitions.
            /// </summary>
            public sealed class NinjaRules
            {
                public string CompileRule { get; }
                public string LinkRule { get; }
                public string ArchiveRule { get; }

                /// <summary>
                /// Creates a new set of Ninja rules with the specified tool paths.
                /// </summary>
                public NinjaRules(string CompilerPath, string LinkerPath, string ArchiverPath)
                {
                    CompileRule = $"""
            rule compile
              command = {CompilerPath} $cflags -c -o $out $in
              description = Compiling $in
            """;

                    LinkRule = $"""
            rule link
              command = {LinkerPath} $ldflags -o $out $in $libs
              description = Linking $out
            """;

                    ArchiveRule = $"""
            rule archive
              command = {ArchiverPath} rcs $out $in
              description = Archiving $out
            """;
                }

            }

        }

    }

}
