import '../../entities/category.dart';
import '../../repositories/category_repository.dart';

class GetCategoriesUsecase {
  final CategoryRepository repository;

  GetCategoriesUsecase(this.repository);

  Future<List<Category>> call() {
    return repository.getCategories();
  }
}
