namespace LumenBuilder
{

    namespace Model
    {

        /// <summary>
        /// Immutable module descriptor parsed from a .build file.
        /// </summary>
        public sealed record ModuleDescriptor(
            string Name,
            string Directory,
            ModuleType Type,
            IReadOnlyList<string> Sources,
            IReadOnlyList<string> PublicIncludes,
            IReadOnlyList<string> PrivateIncludes,
            IReadOnlyList<string> Defines,
            IReadOnlyList<string> Dependencies
        );

    }

}
