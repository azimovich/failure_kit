// class UserRepository with RepositoryHandler {
//   final Dio _dio;
//   UserRepository(this._dio);

//   Future<Either<Failure, String>> fetchProfile() {
//     return call(() async {
//       final response = await _dio.get('/profile');
//       return response.data['name'];
//     });
//   }
// }


// final result = await userRepository.fetchProfile();

// result.fold(
//   (failure) => failure.when(
//     server: (f) => showSnackBar("Server error: ${f.statusCode}"),
//     network: (_) => showSnackBar("No connection"),
//     parsing: (_) => showSnackBar("Data processing error"),
//     unknown: (f) => showSnackBar(f.message),
//   ),
//   (name) => print("User name: $name"),
// );